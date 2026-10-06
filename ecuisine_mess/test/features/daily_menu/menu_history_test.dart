import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/menu_history_result_model.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/menu_history_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/get_menu_history.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/menu_history_bloc.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/get_cuisine_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGetMenuHistory implements GetMenuHistory {
  _FakeGetMenuHistory(this.result);
  final MenuHistoryResult result;

  @override
  Future<MenuHistoryResult> call(GetMenuHistoryParams params) async => result;
}

class _FakeGetCuisineOptions implements GetCuisineOptions {
  _FakeGetCuisineOptions(this.cuisines);
  final List<CuisineOption> cuisines;

  @override
  Future<List<CuisineOption>> call(GetCuisineOptionsParams params) async => cuisines;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MenuHistoryResultModel Tests', () {
    test('parses JSON with menus and total count', () {
      final json = {
        'total': 2,
        'limit': 50,
        'offset': 0,
        'menus': [
          {
            'id': 'm1',
            'menu_date': '2026-10-06',
            'cuisine_id': 'c1',
            'cuisine_name': 'North Indian',
            'meal_type': 'BREAKFAST',
            'is_locked': 1,
            'notes': 'Chef special',
            'items': [
              {
                'id': 'i1',
                'item_name': 'Aloo Paratha',
                'unit': 'Plate',
                'quantity': 2.0,
                'notes': 'Extra butter',
                'category_id': 'cat1',
                'category': 'Main',
                'uom_id': 'u1',
              }
            ],
          },
          {
            'id': 'm2',
            'menu_date': '2026-10-06',
            'cuisine_id': 'c1',
            'cuisine_name': 'North Indian',
            'meal_type': 'LUNCH',
            'is_locked': 0,
            'items': [],
          }
        ],
      };

      final model = MenuHistoryResultModel.fromJson(json);
      expect(model.total, 2);
      expect(model.limit, 50);
      expect(model.offset, 0);
      expect(model.menus.length, 2);

      final entity = model.toEntity();
      expect(entity.total, 2);
      expect(entity.menus.first.cuisineName, 'North Indian');
      expect(entity.menus.first.items.first.itemName, 'Aloo Paratha');
      expect(entity.menus.first.isLocked, isTrue);
    });
  });

  group('MenuHistoryBloc Tests', () {
    late MenuHistoryBloc bloc;
    final fakeCuisines = [
      const CuisineOption(id: 'c1', name: 'North Indian', isActive: true),
      const CuisineOption(id: 'c2', name: 'South Indian', isActive: true),
    ];
    final sampleMenus = [
      const DailyMenu(
        id: 'm1',
        menuDate: '2026-10-06',
        cuisineId: 'c1',
        cuisineName: 'North Indian',
        mealType: 'BREAKFAST',
        items: [
          DailyMenuItem(
            itemId: 'i1',
            itemName: 'Poha',
            unit: 'Plate',
            quantity: 1,
          ),
        ],
      ),
      const DailyMenu(
        id: 'm2',
        menuDate: '2026-10-06',
        cuisineId: 'c1',
        cuisineName: 'North Indian',
        mealType: 'LUNCH',
        items: [
          DailyMenuItem(
            itemId: 'i2',
            itemName: 'Thali',
            unit: 'Plate',
            quantity: 1,
          ),
        ],
      ),
      const DailyMenu(
        id: 'm3',
        menuDate: '2026-10-05',
        cuisineId: 'c2',
        cuisineName: 'South Indian',
        mealType: 'DINNER',
        items: [
          DailyMenuItem(
            itemId: 'i3',
            itemName: 'Dosa',
            unit: 'Nos',
            quantity: 2,
          ),
        ],
      ),
    ];

    setUp(() {
      bloc = MenuHistoryBloc(
        getMenuHistory: _FakeGetMenuHistory(
          MenuHistoryResult(
            total: sampleMenus.length,
            limit: 50,
            offset: 0,
            menus: sampleMenus,
          ),
        ),
        getCuisineOptions: _FakeGetCuisineOptions(fakeCuisines),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('Started event loads cuisines and groups menus into records', () async {
      bloc.add(const MenuHistoryStarted(fromDate: '2026-10-01', toDate: '2026-10-06'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<MenuHistoryState>(
            (s) => s.status == Status.loading && s.fromDate == '2026-10-01' && s.toDate == '2026-10-06',
          ),
          predicate<MenuHistoryState>((s) {
            return s.status == Status.success &&
                s.records.length == 2 &&
                s.records.first.date == '2026-10-06' &&
                s.records.first.cuisineName == 'North Indian' &&
                s.records.first.breakfastCount == 1 &&
                s.records.first.lunchCount == 1 &&
                s.records.first.dinnerCount == 0 &&
                s.records[1].date == '2026-10-05' &&
                s.records[1].dinnerCount == 1;
          }),
        ]),
      );
    });

    test('search query filters records by cuisine name or date', () async {
      bloc.add(const MenuHistoryStarted(fromDate: '2026-10-01', toDate: '2026-10-06'));
      await bloc.stream.firstWhere((s) => s.status == Status.success);

      bloc.add(const MenuHistorySearchChanged('South'));
      await bloc.stream.firstWhere((s) => s.searchQuery == 'South');
      expect(bloc.state.filteredRecords.length, 1);
      expect(bloc.state.filteredRecords.first.cuisineName, 'South Indian');

      bloc.add(const MenuHistorySearchChanged('2026-10-06'));
      await bloc.stream.firstWhere((s) => s.searchQuery == '2026-10-06');
      expect(bloc.state.filteredRecords.length, 1);
      expect(bloc.state.filteredRecords.first.date, '2026-10-06');

      bloc.add(const MenuHistorySearchChanged('nonexistent'));
      await bloc.stream.firstWhere((s) => s.searchQuery == 'nonexistent');
      expect(bloc.state.filteredRecords, isEmpty);
    });
  });

  group('Menu History DI and Route Wiring', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await sl.reset();
      await configureDependencies();
    });

    tearDown(() async {
      await sl.reset();
    });

    test('DI registers GetMenuHistory and MenuHistoryBloc', () {
      expect(sl.isRegistered<GetMenuHistory>(), isTrue);
      expect(sl.isRegistered<MenuHistoryBloc>(), isTrue);
      final bloc = sl<MenuHistoryBloc>();
      expect(bloc, isA<MenuHistoryBloc>());
      bloc.close();
    });

    test('AppRoutes defines menuHistory route', () {
      expect(AppRoutes.menuHistory.path, '/menu/history');
      expect(AppRoutes.menuHistory.name, 'menuHistory');
    });
  });
}

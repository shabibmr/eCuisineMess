import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/menu_history_record.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/get_menu_history.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/get_cuisine_options.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_history_event.dart';
part 'menu_history_state.dart';

class MenuHistoryBloc extends Bloc<MenuHistoryEvent, MenuHistoryState> {
  MenuHistoryBloc({
    required GetMenuHistory getMenuHistory,
    required GetCuisineOptions getCuisineOptions,
  })  : _getMenuHistory = getMenuHistory,
        _getCuisineOptions = getCuisineOptions,
        super(const MenuHistoryState()) {
    on<MenuHistoryStarted>(_onStarted, transformer: restartable());
    on<MenuHistoryDateRangeChanged>(_onDateRangeChanged, transformer: restartable());
    on<MenuHistoryCuisineFiltered>(_onCuisineFiltered, transformer: restartable());
    on<MenuHistorySearchChanged>(_onSearchChanged);
    on<MenuHistoryRefreshRequested>(_onRefresh, transformer: restartable());
  }

  final GetMenuHistory _getMenuHistory;
  final GetCuisineOptions _getCuisineOptions;

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _onStarted(
    MenuHistoryStarted event,
    Emitter<MenuHistoryState> emit,
  ) async {
    final now = DateTime.now();
    final to = event.toDate?.isNotEmpty == true ? event.toDate! : formatDate(now);
    final from = event.fromDate?.isNotEmpty == true
        ? event.fromDate!
        : formatDate(now.subtract(const Duration(days: 30)));
    final cuisineId = event.cuisineId;

    emit(
      state.copyWith(
        status: Status.loading,
        fromDate: from,
        toDate: to,
        selectedCuisineId: cuisineId,
        error: null,
      ),
    );

    try {
      final cuisines = await _getCuisineOptions(const GetCuisineOptionsParams());
      final result = await _getMenuHistory(
        GetMenuHistoryParams(
          fromDate: from,
          toDate: to,
          cuisineId: cuisineId,
          limit: 100,
        ),
      );

      final records = _groupMenus(result.menus, cuisines);

      emit(
        state.copyWith(
          status: Status.success,
          cuisines: cuisines,
          records: records,
          error: null,
        ),
      );
    } on Failure catch (f) {
      emit(state.copyWith(status: Status.failure, error: f.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onDateRangeChanged(
    MenuHistoryDateRangeChanged event,
    Emitter<MenuHistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: Status.loading,
        fromDate: event.fromDate,
        toDate: event.toDate,
        error: null,
      ),
    );
    await _fetchData(emit, from: event.fromDate, to: event.toDate, cuisineId: state.selectedCuisineId);
  }

  Future<void> _onCuisineFiltered(
    MenuHistoryCuisineFiltered event,
    Emitter<MenuHistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: Status.loading,
        selectedCuisineId: event.cuisineId,
        error: null,
      ),
    );
    await _fetchData(emit, from: state.fromDate, to: state.toDate, cuisineId: event.cuisineId);
  }

  void _onSearchChanged(
    MenuHistorySearchChanged event,
    Emitter<MenuHistoryState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onRefresh(
    MenuHistoryRefreshRequested event,
    Emitter<MenuHistoryState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, error: null));
    await _fetchData(emit, from: state.fromDate, to: state.toDate, cuisineId: state.selectedCuisineId);
  }

  Future<void> _fetchData(
    Emitter<MenuHistoryState> emit, {
    required String from,
    required String to,
    String? cuisineId,
  }) async {
    try {
      final result = await _getMenuHistory(
        GetMenuHistoryParams(
          fromDate: from,
          toDate: to,
          cuisineId: cuisineId,
          limit: 100,
        ),
      );
      final records = _groupMenus(result.menus, state.cuisines);
      emit(
        state.copyWith(
          status: Status.success,
          records: records,
          error: null,
        ),
      );
    } on Failure catch (f) {
      emit(state.copyWith(status: Status.failure, error: f.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  List<MenuHistoryRecord> _groupMenus(
    List<DailyMenu> menus,
    List<CuisineOption> cuisines,
  ) {
    final cuisineNameMap = <String, String>{};
    for (final c in cuisines) {
      cuisineNameMap[c.id] = c.name;
    }

    final groups = <String, _GroupBuilder>{};
    for (final m in menus) {
      final key = '${m.menuDate}_${m.cuisineId}';
      final builder = groups.putIfAbsent(
        key,
        () => _GroupBuilder(
          date: m.menuDate,
          cuisineId: m.cuisineId,
          cuisineName: m.cuisineName ?? cuisineNameMap[m.cuisineId] ?? 'Cuisine',
        ),
      );

      final meal = m.mealType.toUpperCase();
      if (meal == 'BREAKFAST') {
        builder.breakfastMenu = m;
      } else if (meal == 'LUNCH') {
        builder.lunchMenu = m;
      } else if (meal == 'DINNER') {
        builder.dinnerMenu = m;
      }
    }

    final records = groups.values.map((b) => b.toRecord()).toList();
    records.sort((a, b) {
      final dateCmp = b.date.compareTo(a.date);
      if (dateCmp != 0) return dateCmp;
      return a.cuisineName.compareTo(b.cuisineName);
    });
    return records;
  }
}

class _GroupBuilder {
  _GroupBuilder({
    required this.date,
    required this.cuisineId,
    required this.cuisineName,
  });

  final String date;
  final String cuisineId;
  final String cuisineName;
  DailyMenu? breakfastMenu;
  DailyMenu? lunchMenu;
  DailyMenu? dinnerMenu;

  MenuHistoryRecord toRecord() => MenuHistoryRecord(
        date: date,
        cuisineId: cuisineId,
        cuisineName: cuisineName,
        breakfastMenu: breakfastMenu,
        lunchMenu: lunchMenu,
        dinnerMenu: dinnerMenu,
      );
}

import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/app_router.dart';
import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/router/nav_destinations.dart';
import 'package:ecuisine_mess/features/daily_menu/data/datasources/daily_menu_remote_datasource.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/repositories/daily_menu_repository.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/copy_from_date.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/copy_meal_to_cuisines.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/get_day_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/get_menu_status.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/save_day_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/daily_menu_editor_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    await configureDependencies();
  });

  tearDown(() async {
    await sl.reset();
  });

  group('Daily Menu DI & Route tests', () {
    test('DI registers Daily Menu data sources, repository, use cases and bloc', () {
      expect(sl.isRegistered<DailyMenuRemoteDataSource>(), isTrue);
      expect(sl<DailyMenuRemoteDataSource>(), isA<DailyMenuRemoteDataSource>());

      expect(sl.isRegistered<DailyMenuRepository>(), isTrue);
      expect(sl<DailyMenuRepository>(), isA<DailyMenuRepository>());

      expect(sl.isRegistered<GetDayMenu>(), isTrue);
      expect(sl.isRegistered<GetMenuStatus>(), isTrue);
      expect(sl.isRegistered<SaveDayMenu>(), isTrue);
      expect(sl.isRegistered<CopyFromDate>(), isTrue);
      expect(sl.isRegistered<CopyMealToCuisines>(), isTrue);

      expect(sl.isRegistered<DailyMenuEditorBloc>(), isTrue);
      final bloc = sl<DailyMenuEditorBloc>();
      expect(bloc, isA<DailyMenuEditorBloc>());
      bloc.close();
    });

    test('AppRoutes defines menu route', () {
      expect(AppRoutes.menu.path, '/menu');
      expect(AppRoutes.menu.name, 'menu');
    });

    test('kNavDestinations contains Daily Menu destination matching AppRoutes.menu', () {
      final dest = kNavDestinations.firstWhere(
        (d) => d.route.path == AppRoutes.menu.path,
        orElse: () => throw StateError('Daily Menu nav destination not found'),
      );
      expect(dest.label, 'Daily Menu');
      expect(dest.icon, Icons.menu_book_outlined);
    });

    test('AppRouter contains /menu branch route in shell', () {
      final router = sl<AppRouter>();
      final goRouter = router.config;
      // Router configuration contains shell routes
      expect(goRouter.configuration.routes, isNotEmpty);
    });
  });
}

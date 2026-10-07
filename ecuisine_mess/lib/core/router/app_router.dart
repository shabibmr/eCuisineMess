import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/router/go_router_refresh.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/features/auth/presentation/pages/login_page.dart';
import 'package:ecuisine_mess/features/bills/presentation/pages/bill_list_page.dart';
import 'package:ecuisine_mess/features/counter/presentation/pages/counter_page.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:ecuisine_mess/features/item_categories/presentation/pages/item_category_list_page.dart';
import 'package:ecuisine_mess/features/items/presentation/pages/item_list_page.dart';
import 'package:ecuisine_mess/features/members/presentation/pages/member_list_page.dart';
import 'package:ecuisine_mess/features/cuisines/presentation/pages/cuisine_editor_page.dart';
import 'package:ecuisine_mess/features/cuisines/presentation/pages/cuisine_list_page.dart';
import 'package:ecuisine_mess/features/meal_times/presentation/pages/meal_time_settings_page.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/pages/daily_menu_editor_page.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/pages/menu_history_page.dart';
import 'package:ecuisine_mess/features/reports/presentation/pages/reports_page.dart';
import 'package:ecuisine_mess/shared/widgets/layout/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  AppRouter(this._auth);

  final AuthBloc _auth;

  late final GoRouter config = GoRouter(
    initialLocation: AppRoutes.counter.path,
    refreshListenable: GoRouterRefreshStream(_auth.stream),
    redirect: _guard,
    routes: [
      GoRoute(
        name: AppRoutes.login.name,
        path: AppRoutes.login.path,
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.home.name,
                path: AppRoutes.home.path,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.counter.name,
                path: AppRoutes.counter.path,
                builder: (context, state) => const CounterPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.members.name,
                path: AppRoutes.members.path,
                builder: (context, state) => const MemberListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.cuisines.name,
                path: AppRoutes.cuisines.path,
                builder: (context, state) => const CuisineListPage(),
                routes: [
                  GoRoute(
                    name: AppRoutes.cuisineNew.name,
                    path: 'new',
                    builder: (context, state) => const CuisineEditorPage(),
                  ),
                  GoRoute(
                    name: AppRoutes.cuisineEdit.name,
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      return CuisineEditorPage(cuisineId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.mealTimes.name,
                path: AppRoutes.mealTimes.path,
                builder: (context, state) => const MealTimeSettingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.items.name,
                path: AppRoutes.items.path,
                builder: (context, state) => const ItemListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.itemCategories.name,
                path: AppRoutes.itemCategories.path,
                builder: (context, state) => const ItemCategoryListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.menu.name,
                path: AppRoutes.menu.path,
                builder: (context, state) {
                  return DailyMenuEditorPage(
                    menuDate: state.uri.queryParameters['date'] ??
                        state.uri.queryParameters['menu_date'],
                    cuisineId: state.uri.queryParameters['cuisine_id'] ??
                        state.uri.queryParameters['cuisineId'],
                    mealType: state.uri.queryParameters['meal'] ??
                        state.uri.queryParameters['meal_type'],
                  );
                },
                routes: [
                  GoRoute(
                    name: AppRoutes.menuHistory.name,
                    path: 'history',
                    builder: (context, state) {
                      return MenuHistoryPage(
                        fromDate: state.uri.queryParameters['from'] ??
                            state.uri.queryParameters['from_date'],
                        toDate: state.uri.queryParameters['to'] ??
                            state.uri.queryParameters['to_date'],
                        cuisineId: state.uri.queryParameters['cuisine_id'] ??
                            state.uri.queryParameters['cuisineId'],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.bills.name,
                path: AppRoutes.bills.path,
                builder: (context, state) => const BillListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRoutes.reports.name,
                path: AppRoutes.reports.path,
                builder: (context, state) => const ReportsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  String? _guard(BuildContext context, GoRouterState state) {
    final auth = _auth.state;
    final loggingIn = state.matchedLocation == AppRoutes.login.path;

    if (auth is AuthUnknown || auth is AuthLoginInProgress) {
      return null;
    }
    if (auth is Unauthenticated) {
      return loggingIn ? null : AppRoutes.login.path;
    }
    if (auth is Authenticated) {
      if (loggingIn) return AppRoutes.defaultAuthenticated.path;
    }
    return null;
  }
}

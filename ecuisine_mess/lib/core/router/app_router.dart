import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/router/go_router_refresh.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/features/auth/presentation/pages/login_page.dart';
import 'package:ecuisine_mess/features/bills/presentation/pages/bill_list_page.dart';
import 'package:ecuisine_mess/features/counter/presentation/pages/counter_page.dart';
import 'package:ecuisine_mess/features/item_categories/presentation/pages/item_category_list_page.dart';
import 'package:ecuisine_mess/features/items/presentation/pages/item_list_page.dart';
import 'package:ecuisine_mess/features/members/presentation/pages/member_list_page.dart';
import 'package:ecuisine_mess/screens/cuisines_screen.dart';
import 'package:ecuisine_mess/screens/reports_screen.dart';
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
                builder: (context, state) => const CuisinesScreen(),
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
                builder: (context, state) => const ReportsScreen(),
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

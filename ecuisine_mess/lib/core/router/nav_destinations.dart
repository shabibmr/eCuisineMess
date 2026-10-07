import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:flutter/material.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final AppRoute route;
}

/// Order matches shell branch indices.
const List<NavDestination> kNavDestinations = [
  NavDestination(
    label: 'Home',
    icon: Icons.dashboard_outlined,
    route: AppRoutes.home,
  ),
  NavDestination(
    label: 'Counter (Kiosk)',
    icon: Icons.point_of_sale,
    route: AppRoutes.counter,
  ),
  NavDestination(
    label: 'Members',
    icon: Icons.badge_outlined,
    route: AppRoutes.members,
  ),
  NavDestination(
    label: 'Cuisines',
    icon: Icons.ramen_dining_outlined,
    route: AppRoutes.cuisines,
  ),
  NavDestination(
    label: 'Meal Times',
    icon: Icons.schedule_outlined,
    route: AppRoutes.mealTimes,
  ),
  NavDestination(
    label: 'Items',
    icon: Icons.restaurant_menu_outlined,
    route: AppRoutes.items,
  ),
  NavDestination(
    label: 'Item Categories',
    icon: Icons.category_outlined,
    route: AppRoutes.itemCategories,
  ),
  NavDestination(
    label: 'Daily Menu',
    icon: Icons.menu_book_outlined,
    route: AppRoutes.menu,
  ),
  NavDestination(
    label: 'Bill Register',
    icon: Icons.receipt_long_outlined,
    route: AppRoutes.bills,
  ),
  NavDestination(
    label: 'Reports',
    icon: Icons.analytics_outlined,
    route: AppRoutes.reports,
  ),
];

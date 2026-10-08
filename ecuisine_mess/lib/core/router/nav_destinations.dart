import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:flutter/material.dart';

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.route,
    this.showInRail = true,
  });

  final String label;
  final IconData icon;
  final AppRoute route;
  final bool showInRail;
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
    label: 'Organizations',
    icon: Icons.business_outlined,
    route: AppRoutes.organizations,
    showInRail: false,
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

final List<NavDestination> kRailDestinations =
    kNavDestinations.where((d) => d.showInRail).toList(growable: false);

int? railIndexForBranch(int branchIndex) {
  if (branchIndex < 0 || branchIndex >= kNavDestinations.length) {
    return null;
  }
  if (!kNavDestinations[branchIndex].showInRail) return null;
  return kNavDestinations.take(branchIndex).where((d) => d.showInRail).length;
}

int branchIndexForRail(int railIndex) {
  var seen = -1;
  for (var i = 0; i < kNavDestinations.length; i++) {
    if (!kNavDestinations[i].showInRail) continue;
    seen++;
    if (seen == railIndex) return i;
  }
  return 0;
}

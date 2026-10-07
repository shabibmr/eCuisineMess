import 'package:ecuisine_mess/features/bills/presentation/pages/bill_list_page.dart';
import 'package:ecuisine_mess/features/counter/presentation/pages/counter_page.dart';
import 'package:ecuisine_mess/features/item_categories/presentation/pages/item_category_list_page.dart';
import 'package:ecuisine_mess/features/items/presentation/pages/item_list_page.dart';
import 'package:ecuisine_mess/features/members/presentation/pages/member_list_page.dart';
import 'package:ecuisine_mess/features/cuisines/presentation/pages/cuisine_list_page.dart';
import 'package:ecuisine_mess/features/meal_times/presentation/pages/meal_time_settings_page.dart';
import 'package:ecuisine_mess/features/reports/presentation/pages/reports_page.dart';
import 'package:flutter/material.dart';

class AppDestination {
  final String label;
  final IconData icon;
  final Widget Function() builder;

  const AppDestination({
    required this.label,
    required this.icon,
    required this.builder,
  });
}

/// Legacy NavigationRail registry (main_layout). Prefer [kNavDestinations].
final List<AppDestination> kAppDestinations = [
  AppDestination(
    label: 'Counter (Kiosk)',
    icon: Icons.point_of_sale,
    builder: () => const CounterPage(),
  ),
  AppDestination(
    label: 'Members',
    icon: Icons.badge_outlined,
    builder: () => const MemberListPage(),
  ),
  AppDestination(
    label: 'Cuisines',
    icon: Icons.ramen_dining_outlined,
    builder: () => const CuisineListPage(),
  ),
  AppDestination(
    label: 'Meal Times',
    icon: Icons.schedule_outlined,
    builder: () => const MealTimeSettingsPage(),
  ),
  AppDestination(
    label: 'Items',
    icon: Icons.restaurant_menu_outlined,
    builder: () => const ItemListPage(),
  ),
  AppDestination(
    label: 'Item Categories',
    icon: Icons.category_outlined,
    builder: () => const ItemCategoryListPage(),
  ),
  AppDestination(
    label: 'Bill Register',
    icon: Icons.receipt_long_outlined,
    builder: () => const BillListPage(),
  ),
  AppDestination(
    label: 'Reports',
    icon: Icons.analytics_outlined,
    builder: () => const ReportsPage(),
  ),
];

import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Current service label plus quick actions. Title and date live in the
/// page's `MasterPage` header.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, this.currentMealName});

  /// Name of the active meal window; null when service is closed.
  final String? currentMealName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = currentMealName != null && currentMealName!.isNotEmpty;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Chip(
          avatar: Icon(
            Icons.circle,
            size: 10,
            color: active ? scheme.primary : scheme.outline,
          ),
          label: Text(
            active ? 'Current service: $currentMealName' : 'Service closed',
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.counter.path),
          icon: const Icon(Icons.point_of_sale, size: 18),
          label: const Text('Open Counter'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.menu.path),
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label: const Text('Daily Menu Editor'),
        ),
      ],
    );
  }
}

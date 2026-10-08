import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, this.currentMealName});
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? scheme.tertiaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.circle : Icons.pause_circle_outline,
                size: 9,
                color: active ? scheme.tertiary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                active ? 'Current service: $currentMealName' : 'Service closed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? scheme.onTertiaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.counter.path),
          icon: const Icon(Icons.point_of_sale_rounded, size: 18),
          label: const Text('Open Counter'),
        ),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.menu.path),
          icon: const Icon(Icons.menu_book_outlined, size: 18),
          label: const Text('Daily Menu'),
        ),
      ],
    );
  }
}

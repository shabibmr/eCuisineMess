import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/utils/meal_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Active cuisines x Breakfast/Lunch/Dinner. Tapping a cell opens the daily
/// menu editor on that date, cuisine and meal.
class MenuReadinessGrid extends StatelessWidget {
  const MenuReadinessGrid({
    super.key,
    required this.rows,
    required this.menuDate,
  });

  final List<MenuReadiness> rows;

  /// `yyyy-MM-dd`, passed through to the editor.
  final String menuDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's menu readiness",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'Tap a cell to edit that meal’s menu',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No active cuisines')),
              )
            else
              Table(
                columnWidths: const {0: FlexColumnWidth(2)},
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    children: [
                      const _Head('Cuisine', align: TextAlign.left),
                      for (final m in MealStyle.all) _Head(m.label),
                    ],
                  ),
                  for (final r in rows)
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: scheme.outlineVariant),
                        ),
                      ),
                      children: [
                        _CuisineCell(row: r),
                        _slot(context, r, 'BREAKFAST', r.breakfast),
                        _slot(context, r, 'LUNCH', r.lunch),
                        _slot(context, r, 'DINNER', r.dinner),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _slot(
    BuildContext context,
    MenuReadiness row,
    String mealType,
    bool filled,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final color = filled ? MealStyle.of(mealType).color : scheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Tooltip(
        message: 'Edit ${MealStyle.of(mealType).label} menu',
        child: InkWell(
          key: ValueKey('readiness-${row.cuisineId}-$mealType'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.go(
            Uri(
              path: AppRoutes.menu.path,
              queryParameters: {
                'date': menuDate,
                'cuisine_id': row.cuisineId,
                'meal': mealType,
              },
            ).toString(),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filled ? Icons.check_circle_outline : Icons.error_outline,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    filled ? 'Set' : 'Not set',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text, {this.align = TextAlign.center});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CuisineCell extends StatelessWidget {
  const _CuisineCell({required this.row});

  final MenuReadiness row;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = switch (row.status) {
      ReadinessStatus.full => 'Full',
      ReadinessStatus.partial => 'Partial',
      ReadinessStatus.empty => 'Empty',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.cuisineName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            '$label · ${row.filledCount}/${row.totalSlots}',
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

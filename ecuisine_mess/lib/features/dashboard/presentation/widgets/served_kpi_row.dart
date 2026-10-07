import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/utils/meal_style.dart';
import 'package:flutter/material.dart';

/// Total plus per-meal served counts for today.
class ServedKpiRow extends StatelessWidget {
  const ServedKpiRow({super.key, required this.served});

  final ServedToday served;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _KpiTile(
        label: 'Total served',
        value: served.total,
        caption: 'Tokens issued today',
        icon: Icons.restaurant,
        accent: Theme.of(context).colorScheme.primary,
      ),
      _mealTile(MealStyle.breakfast, served.breakfast),
      _mealTile(MealStyle.lunch, served.lunch),
      _mealTile(MealStyle.dinner, served.dinner),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 720 ? 4 : 2;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }

  Widget _mealTile(MealStyle style, int value) => _KpiTile(
    label: style.label,
    value: value,
    icon: style.icon,
    accent: style.color,
  );
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.caption,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accent;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accent, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(icon, size: 16, color: accent),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            if (caption != null)
              Text(
                caption!,
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

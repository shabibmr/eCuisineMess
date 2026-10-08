import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/utils/meal_style.dart';
import 'package:ecuisine_mess/shared/widgets/tables/app_kpi_card.dart';
import 'package:flutter/material.dart';

/// Total plus per-meal served counts for today.
class ServedKpiRow extends StatelessWidget {
  const ServedKpiRow({super.key, required this.served});

  final ServedToday served;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      AppKpiCard(
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

  Widget _mealTile(MealStyle style, int value) => AppKpiCard(
        label: style.label,
        value: value,
        icon: style.icon,
        accent: style.color,
      );
}

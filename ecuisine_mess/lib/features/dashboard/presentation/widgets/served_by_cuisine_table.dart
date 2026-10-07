import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/utils/meal_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Served-today counts per cuisine and meal, with a totals row.
class ServedByCuisineTable extends StatelessWidget {
  const ServedByCuisineTable({super.key, required this.rows});

  final List<ServedByCuisine> rows;

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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Served today',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.reports.path),
                  child: const Text('Report ↗'),
                ),
              ],
            ),
            Text(
              'By cuisine and meal',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No active cuisines')),
              )
            else
              _table(context),
          ],
        ),
      ),
    );
  }

  Widget _table(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = rows.fold(0, (s, r) => s + r.breakfast);
    final l = rows.fold(0, (s, r) => s + r.lunch);
    final d = rows.fold(0, (s, r) => s + r.dinner);
    final t = rows.fold(0, (s, r) => s + r.total);

    Widget cell(
      String text, {
      bool bold = false,
      bool head = false,
      bool left = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          text,
          textAlign: left ? TextAlign.left : TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: head ? 12 : 13,
            fontWeight: bold || head ? FontWeight.w600 : FontWeight.normal,
            color: head ? scheme.onSurfaceVariant : null,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    TableRow row(
      List<String> v, {
      bool bold = false,
      bool head = false,
      bool divider = true,
    }) {
      return TableRow(
        decoration: BoxDecoration(
          border: divider
              ? Border(top: BorderSide(color: scheme.outlineVariant))
              : null,
        ),
        children: [
          cell(v[0], bold: bold, head: head, left: true),
          for (final x in v.skip(1)) cell(x, bold: bold, head: head),
        ],
      );
    }

    return Table(
      columnWidths: const {0: FlexColumnWidth(2.2)},
      children: [
        row(
          ['Cuisine', for (final m in MealStyle.all) m.label[0], 'Total'],
          head: true,
          divider: false,
        ),
        for (final r in rows)
          row([
            r.cuisineName,
            '${r.breakfast}',
            '${r.lunch}',
            '${r.dinner}',
            '${r.total}',
          ]),
        row(['Total', '$b', '$l', '$d', '$t'], bold: true),
      ],
    );
  }
}

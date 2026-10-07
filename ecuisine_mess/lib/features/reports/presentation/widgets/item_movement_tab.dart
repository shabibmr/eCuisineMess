import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/period_filters.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/report_tab.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_filter_fields.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_frame.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_table.dart';
import 'package:flutter/material.dart';

String formatQuantity(double q) =>
    q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

class ItemMovementTab extends StatefulWidget {
  const ItemMovementTab({super.key, required this.cuisines});

  final Map<String, String> cuisines;

  @override
  State<ItemMovementTab> createState() => _ItemMovementTabState();
}

class _ItemMovementTabState extends State<ItemMovementTab> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  String? _cuisineId;
  String? _meal;

  ReportQuery _query() => reportQuery({
    'from_date': formatReportDate(_from),
    'to_date': formatReportDate(_to),
    'cuisine_id': _cuisineId,
    'meal_type': _meal,
  });

  @override
  Widget build(BuildContext context) {
    return ReportTab<List<ItemMovementRow>>(
      buildQuery: _query,
      filters: PeriodFilters(
        from: _from,
        to: _to,
        cuisineId: _cuisineId,
        cuisines: widget.cuisines,
        mealType: _meal,
        onFrom: (d) => setState(() => _from = d),
        onTo: (d) => setState(() => _to = d),
        onCuisine: (v) => setState(() => _cuisineId = v),
        onMeal: (v) => setState(() => _meal = v),
      ),
      summary: (rows) => Row(
        children: [
          ReportStat(label: 'Item lines', value: '${rows.length}'),
        ],
      ),
      isEmpty: (rows) => rows.isEmpty,
      result: (rows) => ReportTable(
        columns: const [
          'Item',
          'Category',
          'Cuisine',
          'Unit',
          'Quantity',
          'Tokens',
        ],
        numericColumns: const {4, 5},
        rows: [
          for (final r in rows)
            [
              r.itemName,
              r.category ?? '',
              r.cuisineName,
              r.unit ?? 'Nos',
              formatQuantity(r.totalQuantity),
              '${r.servedCount}',
            ],
        ],
      ),
    );
  }
}

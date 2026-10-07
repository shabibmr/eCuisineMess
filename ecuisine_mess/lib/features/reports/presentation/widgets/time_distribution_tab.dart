import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/period_filters.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/report_tab.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_filter_fields.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_frame.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_table.dart';
import 'package:flutter/material.dart';

class TimeDistributionTab extends StatefulWidget {
  const TimeDistributionTab({super.key, required this.cuisines});

  final Map<String, String> cuisines;

  @override
  State<TimeDistributionTab> createState() => _TimeDistributionTabState();
}

class _TimeDistributionTabState extends State<TimeDistributionTab> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  String? _cuisineId;
  String? _meal;
  int _interval = 60;

  ReportQuery _query() => reportQuery({
    'from_date': formatReportDate(_from),
    'to_date': formatReportDate(_to),
    'cuisine_id': _cuisineId,
    'meal_type': _meal,
    'interval': '$_interval',
  });

  @override
  Widget build(BuildContext context) {
    return ReportTab<TimeDistributionReport>(
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
        extra: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 15, label: Text('15 min')),
              ButtonSegment(value: 30, label: Text('30 min')),
              ButtonSegment(value: 60, label: Text('60 min')),
            ],
            selected: {_interval},
            onSelectionChanged: (s) => setState(() => _interval = s.first),
          ),
        ],
      ),
      summary: (r) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ReportStat(label: 'Total tokens', value: '${r.totalTokens}'),
          ReportStat(
            label: 'Peak slot',
            value: r.peakSlot == null ? '-' : '${r.peakSlot} (${r.peakCount})',
          ),
          ReportStat(label: 'First token', value: r.firstTokenTime ?? '-'),
          ReportStat(label: 'Last token', value: r.lastTokenTime ?? '-'),
        ],
      ),
      isEmpty: (r) => r.slots.isEmpty,
      result: (r) {
        final peak = r.peakCount == 0 ? 1 : r.peakCount;
        return ReportTable(
          columns: const [
            'Time slot',
            'Breakfast',
            'Lunch',
            'Dinner',
            'Total',
            'Traffic',
          ],
          numericColumns: const {1, 2, 3, 4},
          rows: [
            for (final s in r.slots)
              [
                s.label,
                '${s.breakfast}',
                '${s.lunch}',
                '${s.dinner}',
                '${s.total}',
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    value: s.total / peak,
                    minHeight: 8,
                    color: s.label == r.peakSlot ? Colors.orange : null,
                  ),
                ),
              ],
          ],
        );
      },
    );
  }
}

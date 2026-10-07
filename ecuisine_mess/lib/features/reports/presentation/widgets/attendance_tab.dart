import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/period_filters.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/report_tab.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_filter_fields.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_frame.dart';
import 'package:ecuisine_mess/shared/widgets/reports/report_table.dart';
import 'package:flutter/material.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key, required this.cuisines});

  final Map<String, String> cuisines;

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  String? _cuisineId;
  String? _meal;
  bool _absentees = false;

  ReportQuery _query() => reportQuery({
    'from_date': formatReportDate(_from),
    'to_date': formatReportDate(_to),
    'cuisine_id': _cuisineId,
    // Absentees are members with no served bill at all in the period, so a
    // meal filter does not apply to them.
    'meal_type': _absentees ? null : _meal,
    'absentees_only': _absentees ? 'true' : null,
  });

  @override
  Widget build(BuildContext context) {
    return ReportTab<AttendanceReport>(
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
        onMeal: _absentees ? null : (v) => setState(() => _meal = v),
        extra: [
          FilterChip(
            label: const Text('Absentees only'),
            selected: _absentees,
            onSelected: (v) => setState(() => _absentees = v),
          ),
        ],
      ),
      summary: (r) => Row(
        children: [
          ReportStat(
            label: r.absenteesOnly ? 'Absent members' : 'Meals attended',
            value: '${r.count}',
          ),
        ],
      ),
      isEmpty: (r) => r.count == 0,
      result: (r) => r.absenteesOnly
          ? ReportTable(
              columns: const [
                'Member ID',
                'Name',
                'Cuisine',
                'Phone',
                'Valid until',
              ],
              rows: [
                for (final a in r.absentees)
                  [
                    a.memberId,
                    a.memberName,
                    a.cuisineName ?? '',
                    a.phone ?? '',
                    a.validityEnd ?? '',
                  ],
              ],
            )
          : ReportTable(
              columns: const [
                'Date',
                'Time',
                'Member ID',
                'Name',
                'Cuisine',
                'Meal',
                'Token',
              ],
              rows: [
                for (final a in r.records)
                  [
                    a.billDate,
                    a.billTime,
                    a.memberId,
                    a.memberName,
                    a.cuisineName,
                    a.mealType,
                    a.tokenNumber,
                  ],
              ],
            ),
    );
  }
}

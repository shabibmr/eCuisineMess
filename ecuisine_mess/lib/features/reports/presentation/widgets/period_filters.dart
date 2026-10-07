import 'package:ecuisine_mess/shared/widgets/reports/report_filter_fields.dart';
import 'package:flutter/material.dart';

const mealTypeOptions = {
  'BREAKFAST': 'Breakfast',
  'LUNCH': 'Lunch',
  'DINNER': 'Dinner',
};

/// From / To dates plus cuisine and meal pickers, shared by period reports.
class PeriodFilters extends StatelessWidget {
  const PeriodFilters({
    super.key,
    required this.from,
    required this.to,
    required this.cuisineId,
    required this.cuisines,
    required this.onFrom,
    required this.onTo,
    required this.onCuisine,
    this.mealType,
    this.onMeal,
    this.extra = const [],
  });

  final DateTime from;
  final DateTime to;
  final String? cuisineId;

  /// Cuisine id → name.
  final Map<String, String> cuisines;
  final ValueChanged<DateTime> onFrom;
  final ValueChanged<DateTime> onTo;
  final ValueChanged<String?> onCuisine;
  final String? mealType;

  /// Null hides the meal picker.
  final ValueChanged<String?>? onMeal;

  /// Report-specific controls appended to the row.
  final List<Widget> extra;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ReportDateField(label: 'From', value: from, onChanged: onFrom),
        ReportDateField(label: 'To', value: to, onChanged: onTo),
        ReportDropdown<String>(
          label: 'Cuisine',
          value: cuisineId,
          items: cuisines,
          onChanged: onCuisine,
        ),
        if (onMeal != null)
          ReportDropdown<String>(
            label: 'Meal',
            value: mealType,
            items: mealTypeOptions,
            onChanged: onMeal!,
            width: 150,
          ),
        ...extra,
      ],
    );
  }
}

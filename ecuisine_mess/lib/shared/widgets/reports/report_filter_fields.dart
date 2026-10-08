import 'package:ecuisine_mess/shared/widgets/inputs/app_date_picker_field.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _day = DateFormat('yyyy-MM-dd');

String formatReportDate(DateTime d) => _day.format(d);

/// A read-only date field backed by the shared [AppDatePickerField].
class ReportDateField extends StatelessWidget {
  const ReportDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onCleared,
    this.width = 160,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  /// When set, an "x" clears the value (optional dates).
  final VoidCallback? onCleared;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AppDatePickerField(
      width: width,
      label: label,
      value: value,
      hintText: 'Any',
      onChanged: onChanged,
      onCleared: onCleared,
    );
  }
}

/// A compact dropdown backed by the shared [AppDropdown] whose first entry
/// means "no filter" ([null] value).
class ReportDropdown<T> extends StatelessWidget {
  const ReportDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.anyLabel = 'All',
    this.width = 170,
  });

  final String label;
  final T? value;

  /// Value → display text.
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final String anyLabel;
  final double width;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<T?>(
      width: width,
      label: label,
      value: items.containsKey(value) ? value : null,
      placeholderLabel: anyLabel,
      items: [
        for (final e in items.entries)
          AppDropdownItem<T?>(
            value: e.key,
            label: e.value,
          ),
      ],
      onChanged: onChanged,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _day = DateFormat('yyyy-MM-dd');

String formatReportDate(DateTime d) => _day.format(d);

/// A read-only field that opens a date picker.
class ReportDateField extends StatelessWidget {
  const ReportDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onCleared,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  /// When set, an "x" clears the value (optional dates).
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(2020),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) onChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: const OutlineInputBorder(),
            suffixIcon: value != null && onCleared != null
                ? IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onCleared,
                  )
                : const Icon(Icons.calendar_today, size: 16),
          ),
          child: Text(value == null ? 'Any' : formatReportDate(value!)),
        ),
      ),
    );
  }
}

/// A compact dropdown whose first entry means "no filter" ([null] value).
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
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        initialValue: items.containsKey(value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem<T?>(value: null, child: Text(anyLabel)),
          for (final e in items.entries)
            DropdownMenuItem<T?>(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

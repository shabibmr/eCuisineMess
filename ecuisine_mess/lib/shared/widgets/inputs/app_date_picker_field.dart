import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final DateFormat _defaultDateFormat = DateFormat('yyyy-MM-dd');

/// Clickable, read-only form field for picking dates with `yyyy-MM-dd` formatting.
///
/// Complies with Material 3 InputDecorator styling and includes:
/// - Calendar prefix icon and optional clear suffix button.
/// - Configurable [firstDate] and [lastDate].
/// - Support for null values with configurable placeholder or label.
class AppDatePickerField extends StatelessWidget {
  const AppDatePickerField({
    super.key,
    required this.onChanged,
    this.value,
    this.label = 'Date',
    this.hintText,
    this.dateFormat,
    this.firstDate,
    this.lastDate,
    this.onCleared,
    this.enabled = true,
    this.width,
  });

  /// The currently selected date (or null).
  final DateTime? value;

  /// Callback when a date is selected.
  final ValueChanged<DateTime> onChanged;

  /// Optional clear callback. If provided and [value] is non-null, a clear button is rendered.
  final VoidCallback? onCleared;

  /// Field label text.
  final String label;

  /// Optional placeholder when value is null (defaults to "Select date").
  final String? hintText;

  /// Custom DateFormat. Defaults to `yyyy-MM-dd`.
  final DateFormat? dateFormat;

  /// Earliest selectable date. Defaults to DateTime(2020).
  final DateTime? firstDate;

  /// Latest selectable date. Defaults to 5 years in future.
  final DateTime? lastDate;

  /// Whether the field is interactive.
  final bool enabled;

  /// Optional explicit width constraint.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formatter = dateFormat ?? _defaultDateFormat;
    final displayText = value != null ? formatter.format(value!) : '';

    final field = InkWell(
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: firstDate ?? DateTime(2020),
                lastDate: lastDate ?? DateTime(now.year + 5),
              );
              if (picked != null) {
                onChanged(picked);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText ?? 'Select date',
          isDense: true,
          enabled: enabled,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          suffixIcon: value != null && onCleared != null && enabled
              ? IconButton(
                  tooltip: 'Clear date',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onCleared,
                )
              : null,
        ),
        child: Text(
          displayText.isEmpty ? (hintText ?? '') : displayText,
          style: displayText.isEmpty
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(
        width: width,
        child: field,
      );
    }

    return field;
  }
}

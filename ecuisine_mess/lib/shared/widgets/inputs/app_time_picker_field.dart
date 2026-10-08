import 'package:flutter/material.dart';

/// Formats a [TimeOfDay] into `HH:mm` (24-hour format).
String formatTimeOfDay(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Parses an `HH:mm` or `HH:mm:ss` string into a [TimeOfDay]. Returns null if invalid.
TimeOfDay? parseTimeString(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parts = raw.trim().split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return null;
  return TimeOfDay(hour: h, minute: m);
}

/// Clickable, read-only form field for picking times with `HH:mm` formatting.
///
/// Features:
/// - Accepts either [TimeOfDay] or raw `HH:mm` string.
/// - Launches Material 3 [showTimePicker].
/// - Displays clock prefix icon and optional clear suffix button.
class AppTimePickerField extends StatelessWidget {
  const AppTimePickerField({
    super.key,
    required this.onChanged,
    this.value,
    this.timeString,
    this.label = 'Time',
    this.hintText,
    this.onCleared,
    this.enabled = true,
    this.width,
  });

  /// The currently selected time as [TimeOfDay].
  final TimeOfDay? value;

  /// Alternative input: the currently selected time as `HH:mm` string.
  final String? timeString;

  /// Callback when a time is selected. Receives the updated [TimeOfDay] and `HH:mm` string.
  final void Function(TimeOfDay time, String formattedTime) onChanged;

  /// Optional clear callback.
  final VoidCallback? onCleared;

  /// Field label text.
  final String label;

  /// Optional placeholder when value is null.
  final String? hintText;

  /// Whether the field is interactive.
  final bool enabled;

  /// Optional explicit width constraint.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveTime = value ?? parseTimeString(timeString);
    final displayText =
        effectiveTime != null ? formatTimeOfDay(effectiveTime) : '';

    final field = InkWell(
      onTap: enabled
          ? () async {
              final initial = effectiveTime ?? TimeOfDay.now();
              final picked = await showTimePicker(
                context: context,
                initialTime: initial,
              );
              if (picked != null) {
                onChanged(picked, formatTimeOfDay(picked));
              }
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText ?? 'Select time',
          isDense: true,
          enabled: enabled,
          prefixIcon: const Icon(Icons.access_time, size: 18),
          suffixIcon: effectiveTime != null && onCleared != null && enabled
              ? IconButton(
                  tooltip: 'Clear time',
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

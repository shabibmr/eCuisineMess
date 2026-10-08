import 'package:ecuisine_mess/features/meal_times/presentation/bloc/meal_time_settings_bloc.dart';
import 'package:ecuisine_mess/shared/widgets/badges/app_status_badge.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_switch_tile.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_time_picker_field.dart';
import 'package:flutter/material.dart';

class MealTimeRow extends StatefulWidget {
  const MealTimeRow({
    super.key,
    required this.row,
    required this.enabled,
    required this.onChanged,
    required this.onSave,
  });

  final MealTimeRowEdit row;
  final bool enabled;
  final void Function({
    String? name,
    String? startTime,
    String? endTime,
    bool? isActive,
  }) onChanged;
  final VoidCallback onSave;

  static String displayTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length >= 2) {
      final h = parts[0].padLeft(2, '0');
      final m = parts[1].padLeft(2, '0');
      return '$h:$m';
    }
    return value;
  }

  static String toApiTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  static TimeOfDay? parseTimeOfDay(String value) {
    final minutes = MealTimeSettingsBloc.parseMinutes(value);
    if (minutes == null) return null;
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  @override
  State<MealTimeRow> createState() => _MealTimeRowState();
}

class _MealTimeRowState extends State<MealTimeRow> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.row.name);
  }

  @override
  void didUpdateWidget(covariant MealTimeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.row.id != widget.row.id ||
        (!widget.row.dirty && oldWidget.row.name != widget.row.name)) {
      _nameCtrl.text = widget.row.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final enabled = widget.enabled;
    final hasError = row.validationError != null;
    return Card(
      elevation: 0,
      color: hasError ? Colors.red.shade50 : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: hasError ? Colors.red.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.mealType.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (row.dirty)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: AppStatusBadge.unsaved(compact: true),
                  ),
                SizedBox(
                  width: 140,
                  child: AppSwitchTile(
                    title: 'Active',
                    value: row.isActive,
                    enabled: enabled,
                    onChanged: enabled
                        ? (v) => widget.onChanged(isActive: v)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameCtrl,
                    enabled: enabled,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => widget.onChanged(name: v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTimePickerField(
                    label: 'Start',
                    timeString: MealTimeRow.displayTime(row.startTime),
                    enabled: enabled,
                    onChanged: (time, _) =>
                        widget.onChanged(startTime: MealTimeRow.toApiTime(time)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppTimePickerField(
                    label: 'End',
                    timeString: MealTimeRow.displayTime(row.endTime),
                    enabled: enabled,
                    onChanged: (time, _) =>
                        widget.onChanged(endTime: MealTimeRow.toApiTime(time)),
                  ),
                ),
                const SizedBox(width: 8),
                AppSaveButton(
                  label: 'Save',
                  icon: null,
                  onPressed: enabled && row.dirty ? widget.onSave : null,
                ),
              ],
            ),
            if (row.validationError != null) ...[
              const SizedBox(height: 8),
              Text(
                row.validationError!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

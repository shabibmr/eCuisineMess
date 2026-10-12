import 'package:ecuisine_mess/shared/widgets/badges/app_status_badge.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_date_picker_field.dart';
import 'package:flutter/material.dart';

/// Top date controls + actions (mock-ui toolbar).
class MenuDateBar extends StatelessWidget {
  const MenuDateBar({
    super.key,
    required this.menuDate,
    required this.enabled,
    required this.readOnly,
    required this.canSave,
    required this.dirty,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onJumpToday,
    required this.onDateChanged,
    required this.onCopyFromDate,
    required this.onHistory,
    required this.onReset,
    required this.onSave,
    this.isSaving = false,
  });

  final String menuDate;
  final bool enabled;
  final bool readOnly;
  final bool canSave;
  final bool dirty;
  final bool isSaving;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onJumpToday;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onCopyFromDate;
  final VoidCallback onHistory;
  final VoidCallback onReset;
  final VoidCallback onSave;

  DateTime? get _parsedDate {
    final parts = menuDate.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: enabled ? onPrevDay : null,
                  icon: const Icon(Icons.chevron_left),
                  visualDensity: VisualDensity.compact,
                ),
                AppDatePickerField(
                  key: ValueKey('menu-date-$menuDate'),
                  label: 'Date',
                  value: _parsedDate,
                  width: 170,
                  enabled: enabled,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2040),
                  onChanged: onDateChanged,
                ),
                IconButton(
                  tooltip: 'Next day',
                  onPressed: enabled ? onNextDay : null,
                  icon: const Icon(Icons.chevron_right),
                  visualDensity: VisualDensity.compact,
                ),
                TextButton(
                  onPressed: enabled ? onJumpToday : null,
                  child: const Text('Today'),
                ),
                if (dirty)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: AppStatusBadge.unsaved(compact: true),
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: enabled && !readOnly ? onCopyFromDate : null,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy From Date…'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('History'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: enabled && !readOnly && dirty ? onReset : null,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 8),
                AppSaveButton(
                  label: 'Save Menu',
                  icon: Icons.save,
                  isLoading: isSaving,
                  onPressed: enabled && canSave ? onSave : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
    required this.onPickDate,
    required this.onCopyFromDate,
    required this.onHistory,
    required this.onReset,
    required this.onSave,
  });

  final String menuDate;
  final bool enabled;
  final bool readOnly;
  final bool canSave;
  final bool dirty;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onJumpToday;
  final VoidCallback onPickDate;
  final VoidCallback onCopyFromDate;
  final VoidCallback onHistory;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                Text(
                  'Date:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Previous day',
                  onPressed: enabled ? onPrevDay : null,
                  icon: const Icon(Icons.chevron_left),
                  visualDensity: VisualDensity.compact,
                ),
                OutlinedButton(
                  onPressed: enabled ? onPickDate : null,
                  child: Text(
                    menuDate.isEmpty ? 'Select date' : menuDate,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
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
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Chip(
                      label: const Text('Unsaved', style: TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.secondaryContainer,
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    ),
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
                FilledButton.icon(
                  onPressed: enabled && canSave ? onSave : null,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save Menu'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

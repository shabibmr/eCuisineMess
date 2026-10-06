import 'package:flutter/material.dart';

/// Breakfast / Lunch / Dinner segmented control + meal actions.
class MenuMealTabs extends StatelessWidget {
  const MenuMealTabs({
    super.key,
    required this.selectedMealType,
    required this.breakfastCount,
    required this.lunchCount,
    required this.dinnerCount,
    required this.enabled,
    required this.readOnly,
    required this.onMealSelected,
    required this.onAddAllMapped,
    required this.onCopyToCuisines,
  });

  final String selectedMealType;
  final int breakfastCount;
  final int lunchCount;
  final int dinnerCount;
  final bool enabled;
  final bool readOnly;
  final ValueChanged<String> onMealSelected;
  final VoidCallback onAddAllMapped;
  final VoidCallback onCopyToCuisines;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'BREAKFAST',
              icon: const Icon(Icons.wb_twilight, size: 16),
              label: Text('Breakfast ($breakfastCount)'),
            ),
            ButtonSegment(
              value: 'LUNCH',
              icon: const Icon(Icons.wb_sunny_outlined, size: 16),
              label: Text('Lunch ($lunchCount)'),
            ),
            ButtonSegment(
              value: 'DINNER',
              icon: const Icon(Icons.nights_stay_outlined, size: 16),
              label: Text('Dinner ($dinnerCount)'),
            ),
          ],
          selected: {selectedMealType},
          onSelectionChanged: enabled
              ? (selection) {
                  if (selection.isEmpty) return;
                  onMealSelected(selection.first);
                }
              : null,
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: enabled && !readOnly ? onAddAllMapped : null,
              icon: const Icon(Icons.playlist_add, size: 16),
              label: const Text('Add All Mapped'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: enabled && !readOnly ? onCopyToCuisines : null,
              icon: const Icon(Icons.copy_all, size: 16),
              label: const Text('Copy to other cuisines…'),
            ),
          ],
        ),
      ],
    );
  }
}

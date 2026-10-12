import 'package:ecuisine_mess/shared/widgets/inputs/app_date_picker_field.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_dropdown.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_search_field.dart';
import 'package:flutter/material.dart';

class BillFiltersBar extends StatelessWidget {
  const BillFiltersBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.mealType,
    required this.status,
    required this.billDate,
    required this.onMealTypeChanged,
    required this.onStatusChanged,
    required this.onDateChanged,
    required this.onClearDate,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String? mealType;
  final String? status;
  final String? billDate;
  final ValueChanged<String?> onMealTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onClearDate;

  DateTime? get _parsedDate {
    final raw = billDate;
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      children: [
        AppSearchField(
          controller: searchController,
          hintText: 'Search by token number, bill number, or member name...',
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppDropdown<String>(
                key: ValueKey('meal-$mealType'),
                value: mealType,
                label: 'Meal',
                placeholderLabel: 'All meals',
                items: const [
                  AppDropdownItem(value: 'BREAKFAST', label: 'Breakfast'),
                  AppDropdownItem(value: 'LUNCH', label: 'Lunch'),
                  AppDropdownItem(value: 'DINNER', label: 'Dinner'),
                ],
                onChanged: onMealTypeChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppDropdown<String>(
                key: ValueKey('status-$status'),
                value: status,
                label: 'Status',
                placeholderLabel: 'All statuses',
                items: const [
                  AppDropdownItem(value: 'SERVED', label: 'Served'),
                  AppDropdownItem(value: 'CANCELLED', label: 'Cancelled'),
                ],
                onChanged: onStatusChanged,
              ),
            ),
            const SizedBox(width: 12),
            AppDatePickerField(
              key: ValueKey('date-$billDate'),
              label: 'Date',
              value: _parsedDate,
              width: 180,
              firstDate: DateTime(now.year - 2),
              lastDate: DateTime(now.year + 1),
              onChanged: onDateChanged,
              onCleared: billDate != null ? onClearDate : null,
            ),
          ],
        ),
      ],
    );
  }
}

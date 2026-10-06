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
    required this.onPickDate,
    required this.onClearDate,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String? mealType;
  final String? status;
  final String? billDate;
  final ValueChanged<String?> onMealTypeChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText:
                'Search by token number, bill number, or member name...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: mealType,
                decoration: const InputDecoration(
                  labelText: 'Meal',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All meals')),
                  DropdownMenuItem(
                    value: 'BREAKFAST',
                    child: Text('Breakfast'),
                  ),
                  DropdownMenuItem(value: 'LUNCH', child: Text('Lunch')),
                  DropdownMenuItem(value: 'DINNER', child: Text('Dinner')),
                ],
                onChanged: onMealTypeChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All statuses')),
                  DropdownMenuItem(value: 'SERVED', child: Text('Served')),
                  DropdownMenuItem(
                    value: 'CANCELLED',
                    child: Text('Cancelled'),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(billDate ?? 'Date'),
            ),
            if (billDate != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Clear date',
                onPressed: onClearDate,
                icon: const Icon(Icons.clear, size: 18),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

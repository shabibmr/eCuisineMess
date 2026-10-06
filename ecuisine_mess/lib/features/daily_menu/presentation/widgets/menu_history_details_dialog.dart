import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/menu_history_record.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/widgets/menu_history_copy_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuHistoryDetailsDialog extends StatelessWidget {
  const MenuHistoryDetailsDialog({
    super.key,
    required this.record,
  });

  final MenuHistoryRecord record;

  static Future<void> show(BuildContext context, MenuHistoryRecord record) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => MenuHistoryDetailsDialog(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.history, size: 24, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${record.cuisineName} — ${record.date}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (record.isLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Locked', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MealSection(
                title: 'Breakfast',
                icon: Icons.wb_twilight,
                items: record.breakfastItems,
                notes: record.breakfastMenu?.notes,
              ),
              const SizedBox(height: 12),
              _MealSection(
                title: 'Lunch',
                icon: Icons.wb_sunny_outlined,
                items: record.lunchItems,
                notes: record.lunchMenu?.notes,
              ),
              const SizedBox(height: 12),
              _MealSection(
                title: 'Dinner',
                icon: Icons.nights_stay_outlined,
                items: record.dinnerItems,
                notes: record.dinnerMenu?.notes,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.copy, size: 16),
          label: const Text('Copy to date'),
          onPressed: () {
            Navigator.of(context).pop();
            MenuHistoryCopyDialog.show(context, sourceRecord: record);
          },
        ),
        FilledButton.icon(
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Open in Editor'),
          onPressed: () {
            Navigator.of(context).pop();
            context.goNamed(
              AppRoutes.menu.name,
              queryParameters: {
                'date': record.date,
                'cuisine_id': record.cuisineId,
              },
            );
          },
        ),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  const _MealSection({
    required this.title,
    required this.icon,
    required this.items,
    this.notes,
  });

  final String title;
  final IconData icon;
  final List<DailyMenuItem> items;
  final String? notes;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  items.isEmpty ? 'Empty' : '${items.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: items.isEmpty ? Colors.grey : Colors.black87,
                    fontWeight: items.isEmpty ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (notes != null && notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Note: $notes',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ],
            const Divider(height: 16),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text('No items planned for this meal slot', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                children: [
                  const TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text('Qty', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  for (final it in items)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(it.itemName, style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(it.unit, style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            it.quantity % 1 == 0 ? it.quantity.toInt().toString() : it.quantity.toString(),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

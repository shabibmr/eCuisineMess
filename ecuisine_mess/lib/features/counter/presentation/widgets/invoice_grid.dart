import 'package:ecuisine_mess/features/counter/domain/entities/counter_line_item.dart';
import 'package:flutter/material.dart';

class InvoiceGrid extends StatelessWidget {
  const InvoiceGrid({
    super.key,
    required this.items,
    required this.mealType,
  });

  final List<CounterLineItem> items;
  final String mealType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Entitled Meal Items ($mealType):',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final itm = items[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFFDCFCE7),
                child: Icon(Icons.check, size: 16, color: Colors.green),
              ),
              title: Text(
                itm.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Unit: ${itm.unit} • Category: ${itm.category}'),
              trailing: Text(
                'Qty: ${itm.quantity.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

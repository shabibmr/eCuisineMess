import 'package:flutter/material.dart';

class TokenSlipDialog extends StatelessWidget {
  final Map<String, dynamic> bill;
  final bool isReprint;

  const TokenSlipDialog({
    super.key,
    required this.bill,
    this.isReprint = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = bill['items'] as List<dynamic>? ?? [];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              const Text(
                'eCuisine Mess Counter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const Text(
                'MEAL ENTITLEMENT TOKEN',
                style: TextStyle(fontSize: 12, color: Colors.black54, letterSpacing: 0.5),
              ),
              const Divider(thickness: 1.5, height: 24),

              if (isReprint)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade600),
                  ),
                  child: const Text(
                    '*** DUPLICATE REPRINT ***',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                ),

              // Large Token Number
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Center(
                  child: Text(
                    bill['token_number'] ?? 'T-0000',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Member & Meal Meta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Member:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  Text(
                    bill['member_name'] ?? 'Guest',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Meal / Cuisine:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  Text(
                    '${bill['meal_type']} • ${bill['cuisine']}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Date & Time:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  Text(
                    '${bill['date']} ${bill['time']}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Items table
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Entitled Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 6),
              ...items.map((item) {
                final name = item is Map ? (item['name'] ?? item['item_name']) : item.toString();
                final qty = item is Map ? (item['quantity'] ?? 1) : 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 14, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name.toString(),
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x$qty',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Total Entitlement Price:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('0.00 AED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 20),

              // Print / Dismiss buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Close & Print Slip'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../services/api_service.dart';
import '../widgets/token_slip_dialog.dart';

class BillRegisterScreen extends StatefulWidget {
  const BillRegisterScreen({super.key});

  @override
  State<BillRegisterScreen> createState() => _BillRegisterScreenState();
}

class _BillRegisterScreenState extends State<BillRegisterScreen> {
  final ApiService _api = ApiService();
  List<Bill> _bills = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    try {
      final list = await _api.fetchBills(search: _search);
      setState(() => _bills = list);
    } catch (_) {} finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBill(Bill bill) async {
    final reasonController = TextEditingController(text: 'Customer cancellation / duplicate');
    final cancelledByController = TextEditingController(text: 'Supervisor Admin');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cancel Bill ${bill.billNumber}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cancelled vouchers are marked as CANCELLED and excluded from daily meal accounts.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Cancellation Reason', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cancelledByController,
              decoration: const InputDecoration(labelText: 'Authorized Supervisor', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await _api.cancelBill(
        bill.id,
        reason: reasonController.text.trim(),
        cancelledBy: cancelledByController.text.trim(),
      );
      if (ok) {
        _loadBills();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Bill & Token Register', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Audit trail of all issued tokens, reprints and supervisor cancellations', style: TextStyle(color: Colors.black54)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadBills,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by token number, bill number, or member name...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (val) {
              _search = val;
              _loadBills();
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bills.isEmpty
                    ? const Center(child: Text('No bills found'))
                    : Card(
                        child: ListView.separated(
                          itemCount: _bills.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final b = _bills[index];
                            final isCancelled = b.status == 'CANCELLED';
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isCancelled ? Colors.grey.shade200 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isCancelled ? Colors.grey : Colors.blue.shade300),
                                ),
                                child: Text(
                                  b.tokenNumber,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isCancelled ? Colors.grey.shade600 : Colors.blue.shade900,
                                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${b.memberName} (${b.memberCode}) • ${b.cuisineName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: Text(
                                '${b.billNumber} • ${b.mealType} • ${b.billDate} ${b.billTime}'
                                '${b.isOverride ? " • [OVERRIDE]" : ""}'
                                '${isCancelled ? " • [CANCELLED: ${b.overrideReason ?? 'By supervisor'}]" : ""}',
                                style: TextStyle(color: isCancelled ? Colors.red : Colors.black54),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.print, size: 20),
                                    tooltip: 'Reprint Token Slip',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => TokenSlipDialog(
                                          bill: {
                                            'token_number': b.tokenNumber,
                                            'member_name': b.memberName,
                                            'cuisine': b.cuisineName,
                                            'meal_type': b.mealType,
                                            'date': b.billDate,
                                            'time': b.billTime,
                                            'items': b.items,
                                          },
                                          isReprint: true,
                                        ),
                                      );
                                    },
                                  ),
                                  if (!isCancelled)
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                                      tooltip: 'Cancel Bill',
                                      onPressed: () => _cancelBill(b),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

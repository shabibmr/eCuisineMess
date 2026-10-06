import 'package:flutter/material.dart';

class BillCancelDialog extends StatefulWidget {
  const BillCancelDialog({
    super.key,
    required this.billNumber,
  });

  final String billNumber;

  @override
  State<BillCancelDialog> createState() => _BillCancelDialogState();
}

class _BillCancelDialogState extends State<BillCancelDialog> {
  late final TextEditingController _reasonController;
  late final TextEditingController _cancelledByController;

  @override
  void initState() {
    super.initState();
    _reasonController =
        TextEditingController(text: 'Customer cancellation / duplicate');
    _cancelledByController =
        TextEditingController(text: 'Supervisor Admin');
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _cancelledByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cancel Bill ${widget.billNumber}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Cancelled vouchers are marked as CANCELLED and excluded from daily meal accounts.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Cancellation Reason',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _cancelledByController,
            decoration: const InputDecoration(
              labelText: 'Authorized Supervisor',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              (
                reason: _reasonController.text.trim(),
                cancelledBy: _cancelledByController.text.trim(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Cancellation'),
        ),
      ],
    );
  }
}

typedef BillCancelResult = ({String reason, String cancelledBy});

import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:flutter/material.dart';

class CounterActionBar extends StatelessWidget {
  const CounterActionBar({
    super.key,
    required this.onSavePrint,
    required this.onClear,
    required this.onSupervisor,
    this.lastTokenSummary,
    this.busy = false,
    this.canSave = false,
    this.canOverride = false,
  });

  final VoidCallback onSavePrint;
  final VoidCallback onClear;
  final VoidCallback onSupervisor;
  final String? lastTokenSummary;
  final bool busy;
  final bool canSave;
  final bool canOverride;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Amount (Meal Entitlement):',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            Text(
              '0.00 AED',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.green.shade700,
              ),
            ),
            if (lastTokenSummary != null)
              Text(
                'Last token: $lastTokenSummary',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
          ],
        ),
        const Spacer(),
        if (canOverride)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton.icon(
              onPressed: onSupervisor,
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text('Supervisor (F8)'),
            ),
          ),
        ElevatedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Clear (Esc)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        AppSaveButton(
          label: 'Save & Issue Token (F10)',
          loadingLabel: 'Issuing...',
          icon: Icons.print,
          isLoading: busy,
          onPressed: canSave ? onSavePrint : null,
        ),
      ],
    );
  }
}

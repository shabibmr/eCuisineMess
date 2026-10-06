import 'package:flutter/material.dart';

class RejectBanner extends StatelessWidget {
  const RejectBanner({
    super.key,
    required this.message,
    this.showOverride = false,
    this.onOverride,
  });

  final String message;
  final bool showOverride;
  final VoidCallback? onOverride;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entitlement Rejected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                Text(
                  message,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
          if (showOverride && onOverride != null)
            ElevatedButton.icon(
              onPressed: onOverride,
              icon: const Icon(Icons.lock_open, size: 16),
              label: const Text('Supervisor Override (F8)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

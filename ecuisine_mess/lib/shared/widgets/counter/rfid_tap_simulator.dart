import 'package:flutter/material.dart';

class RfidTapSimulator extends StatelessWidget {
  const RfidTapSimulator({super.key, required this.onScan});

  final void Function(String rfid) onScan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.nfc, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'RFID Demo Tap Simulator',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  label: 'Rahul Krishnan (Valid)',
                  tag: 'E280116060000204',
                  color: Colors.green.shade50,
                  textColor: Colors.green.shade900,
                  icon: Icons.check_circle_outline,
                ),
                _buildChip(
                  label: 'Mohammed (Arabic Cuis.)',
                  tag: 'E280116060000205',
                  color: Colors.blue.shade50,
                  textColor: Colors.blue.shade900,
                  icon: Icons.person_outline,
                ),
                _buildChip(
                  label: 'Suresh (Expired Card)',
                  tag: 'E280116060000210',
                  color: Colors.red.shade50,
                  textColor: Colors.red.shade900,
                  icon: Icons.error_outline,
                ),
                _buildChip(
                  label: 'Tariq (Suspended)',
                  tag: 'E280116060000211',
                  color: Colors.amber.shade50,
                  textColor: Colors.amber.shade900,
                  icon: Icons.block,
                ),
                _buildChip(
                  label: 'Unregistered Card',
                  tag: 'UNKNOWN_RFID_9999',
                  color: Colors.grey.shade100,
                  textColor: Colors.black87,
                  icon: Icons.help_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required String tag,
    required Color color,
    required Color textColor,
    required IconData icon,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: textColor),
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color,
      side: BorderSide(color: textColor.withValues(alpha: 0.3)),
      onPressed: () => onScan(tag),
    );
  }
}

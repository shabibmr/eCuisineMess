import 'package:flutter/material.dart';

/// Demo PIN remains `1234` until backend roles (FE-5).
class SupervisorOverrideDialog extends StatefulWidget {
  const SupervisorOverrideDialog({super.key, required this.onAuthorized});

  final void Function(String supervisor, String reason) onAuthorized;

  @override
  State<SupervisorOverrideDialog> createState() =>
      _SupervisorOverrideDialogState();
}

class _SupervisorOverrideDialogState extends State<SupervisorOverrideDialog> {
  final _supervisorController = TextEditingController(text: 'Manager Dave');
  final _passwordController = TextEditingController();
  String _selectedReason = 'Duplicate Meal Exception';
  String? _error;

  static const _reasons = [
    'Duplicate Meal Exception',
    'Guest / VIP Entitlement',
    'Previous Token Misprint / Lost',
    'Card Scanner Fallback',
    'Administrative Approval',
  ];

  @override
  void dispose() {
    _supervisorController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _verifyAndSubmit() {
    if (_passwordController.text.trim() != '1234') {
      setState(() {
        _error = 'Invalid supervisor PIN (Default demo PIN is 1234)';
      });
      return;
    }
    widget.onAuthorized(_supervisorController.text.trim(), _selectedReason);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.orange),
          SizedBox(width: 10),
          Text('Supervisor Authorization'),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Authorization is required to bypass meal service restrictions or issue an override token.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _supervisorController,
              decoration: const InputDecoration(
                labelText: 'Supervisor Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'PIN (Default: 1234)',
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: _error,
              ),
              onSubmitted: (_) => _verifyAndSubmit(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Reason for Override',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _reasons
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedReason = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _verifyAndSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
          ),
          child: const Text('Authorize Override'),
        ),
      ],
    );
  }
}

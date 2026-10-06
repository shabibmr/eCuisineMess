import 'package:flutter/material.dart';

class RfidInputBar extends StatelessWidget {
  const RfidInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String tag) onSubmit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.nfc),
              hintText:
                  'Scan / Tap RFID Card (or enter tag number and press Enter)...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => onSubmit(controller.text),
              ),
            ),
            onSubmitted: onSubmit,
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Clear (Esc)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.black87,
          ),
        ),
      ],
    );
  }
}

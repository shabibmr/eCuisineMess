import 'package:flutter/material.dart';

/// Shows a form dialog. Returns true only when the form validates.
/// Caller performs the API save after the dialog closes.
Future<bool> showAppFormDialog({
  required BuildContext context,
  required String title,
  required Widget body,
  required GlobalKey<FormState> formKey,
  String confirmLabel = 'Save',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(ctx, true);
            }
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

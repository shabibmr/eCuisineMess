import 'package:flutter/material.dart';

/// Consolidated, responsive form modal dialog with built-in validation support.
///
/// Features:
/// - Enforces responsive dialog width between [minWidth] (420px) and [maxWidth] (560px).
/// - Scrollable body with keyboard padding avoidance.
/// - Validates [formKey] before closing and resolves with `true`.
/// - Single source of truth across the entire app.
///
/// Usage:
/// ```dart
/// final ok = await showAppFormDialog(
///   context: context,
///   title: 'Add Category',
///   formKey: formKey,
///   body: CategoryFormFields(...),
/// );
/// ```
Future<bool> showAppFormDialog({
  required BuildContext context,
  required String title,
  required Widget body,
  required GlobalKey<FormState> formKey,
  String confirmLabel = 'Save',
  String cancelLabel = 'Cancel',
  double minWidth = 420.0,
  double maxWidth = 560.0,
  bool barrierDismissible = false,
  Widget? leadingTitleIcon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AppFormDialog(
      title: title,
      body: body,
      formKey: formKey,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      minWidth: minWidth,
      maxWidth: maxWidth,
      leadingTitleIcon: leadingTitleIcon,
    ),
  );
  return result == true;
}

/// Modal container widget for responsive forms.
class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    super.key,
    required this.title,
    required this.body,
    required this.formKey,
    this.confirmLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.minWidth = 420.0,
    this.maxWidth = 560.0,
    this.leadingTitleIcon,
  });

  final String title;
  final Widget body;
  final GlobalKey<FormState> formKey;
  final String confirmLabel;
  final String cancelLabel;
  final double minWidth;
  final double maxWidth;
  final Widget? leadingTitleIcon;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final effectiveWidth = (screenSize.width * 0.9).clamp(minWidth, maxWidth);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      title: Row(
        children: [
          if (leadingTitleIcon != null) ...[
            leadingTitleIcon!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: effectiveWidth,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: body,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState?.validate() == true) {
              Navigator.of(context).pop(true);
            }
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

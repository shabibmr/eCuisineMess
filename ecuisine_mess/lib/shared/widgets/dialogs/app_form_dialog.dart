import 'package:ecuisine_mess/shared/widgets/dialogs/app_glass_lift_dialog.dart';
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
  final result = await showAppGlassLiftDialog<bool>(
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
    this.onConfirm,
  });

  final String title;
  final Widget body;
  final GlobalKey<FormState> formKey;
  final String confirmLabel;
  final String cancelLabel;
  final double minWidth;
  final double maxWidth;
  final Widget? leadingTitleIcon;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final effectiveWidth = (screenSize.width * 0.9).clamp(minWidth, maxWidth);

    return AppGlassLiftShell(
      width: effectiveWidth,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Row(
          children: [
            if (leadingTitleIcon != null) ...[
              leadingTitleIcon!,
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: body,
          ),
        ),
      ),
      actions: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              // Null result stays compatible with showDialog<T> typed routes.
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelLabel),
            ),
            const SizedBox(width: 8),
            AppHoverLift(
              child: FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    if (onConfirm != null) {
                      onConfirm!();
                    } else {
                      Navigator.of(context).pop(true);
                    }
                  }
                },
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

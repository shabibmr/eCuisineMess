import 'package:ecuisine_mess/shared/widgets/buttons/app_danger_button.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_glass_lift_dialog.dart';
import 'package:flutter/material.dart';

/// Standard confirmation modal dialog returning a `Future<bool>`.
///
/// Designed to replace repetitive confirmation dialogs across entity management
/// (deleting cuisines, removing members, cancelling bills, discarding forms).
///
/// Usage:
/// ```dart
/// final confirmed = await AppConfirmDialog.show(
///   context: context,
///   title: 'Delete Cuisine?',
///   message: 'Are you sure you want to delete "Arabic"?',
///   confirmLabel: 'Delete',
///   isDestructive: true,
/// );
/// ```
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  /// Static helper to display the dialog and return a boolean result.
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showAppGlassLiftDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result == true;
  }

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerIcon = icon ??
        (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline);

    return AppGlassLiftShell(
      maxWidth: 380,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Column(
          children: [
            Icon(
              headerIcon,
              color: isDestructive
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ),
      actions: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            const SizedBox(width: 8),
            AppHoverLift(
              child: isDestructive
                  ? AppDangerButton(
                      label: confirmLabel,
                      onPressed: () => Navigator.of(context).pop(true),
                    )
                  : FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(confirmLabel),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

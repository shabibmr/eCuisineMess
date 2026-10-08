import 'package:flutter/material.dart';

/// Destructive/warning action button for deletions and irreversible actions.
///
/// Features:
/// - Distinctive error/red color scheme adhering to Material 3 error tokens.
/// - Built-in [isLoading] spinner support with auto-disabling.
/// - Available in filled (default), outlined, or text variant.
class AppDangerButton extends StatelessWidget {
  const AppDangerButton({
    super.key,
    required this.onPressed,
    this.label = 'Delete',
    this.loadingLabel,
    this.isLoading = false,
    this.icon = Icons.delete_outline,
    this.outlined = false,
    this.isFullWidth = false,
  });

  /// Action executed on tap. Disabled when null or when [isLoading] is true.
  final VoidCallback? onPressed;

  /// Default text shown on the button.
  final String label;

  /// Custom text shown during [isLoading] state. If omitted, defaults to "Deleting...".
  final String? loadingLabel;

  /// Whether the button is in an active loading state.
  final bool isLoading;

  /// Leading icon displayed when not loading.
  final IconData? icon;

  /// If true, renders an outlined danger button instead of filled.
  final bool outlined;

  /// Whether the button should stretch to full parent width.
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final onErrorColor = theme.colorScheme.onError;
    final effectiveLabel = isLoading ? (loadingLabel ?? 'Deleting...') : label;

    final child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                outlined ? errorColor : onErrorColor,
              ),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (icon != null || isLoading) const SizedBox(width: 8),
        Text(effectiveLabel),
      ],
    );

    final Widget button;
    if (outlined) {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: errorColor,
          side: BorderSide(color: errorColor),
        ),
        child: child,
      );
    } else {
      button = FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: errorColor,
          foregroundColor: onErrorColor,
        ),
        child: child,
      );
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

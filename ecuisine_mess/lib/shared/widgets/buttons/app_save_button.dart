import 'package:flutter/material.dart';

/// Standard submit/save button with built-in loading state indicator.
///
/// Features:
/// - Smooth progress spinner substitution when [isLoading] is true.
/// - Disables click action automatically while saving or if [onPressed] is null.
/// - Adheres strictly to Material 3 button dimensions, typography, and states.
class AppSaveButton extends StatelessWidget {
  const AppSaveButton({
    super.key,
    required this.onPressed,
    this.label = 'Save',
    this.loadingLabel,
    this.isLoading = false,
    this.icon = Icons.check,
    this.isFullWidth = false,
  });

  /// Action executed on tap. Disabled when null or when [isLoading] is true.
  final VoidCallback? onPressed;

  /// Default text shown on the button.
  final String label;

  /// Custom text shown during [isLoading] state. If omitted, defaults to "Saving...".
  final String? loadingLabel;

  /// Whether the button is in an active saving/submitting state.
  final bool isLoading;

  /// Leading icon displayed when not loading.
  final IconData? icon;

  /// Whether the button should stretch to full parent width.
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = isLoading ? (loadingLabel ?? 'Saving...') : label;

    final child = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (icon != null || isLoading) const SizedBox(width: 8),
        Text(effectiveLabel),
      ],
    );

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

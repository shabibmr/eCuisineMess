import 'package:flutter/material.dart';

/// Standard standardized `FilledButton.icon` with '+' (create) icon.
///
/// Designed to provide consistent visual affordance across all entity list
/// pages and master views.
class AppCreateButton extends StatelessWidget {
  const AppCreateButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.add,
    this.tooltip,
  });

  /// Action invoked when tapping the button.
  final VoidCallback? onPressed;

  /// Label text displayed on the button (e.g. "New Cuisine", "Add Member").
  final String label;

  /// Icon displayed before the label. Defaults to [Icons.add].
  final IconData icon;

  /// Optional tooltip hint for accessibility and desktop mouse hover.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

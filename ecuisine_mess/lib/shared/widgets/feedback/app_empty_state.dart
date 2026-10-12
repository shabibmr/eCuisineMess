import 'package:flutter/material.dart';

/// Centered empty state view with title, subtitle, icon, and optional call-to-action button.
///
/// Provides a consistent "no records found" / inbox zero experience across all
/// entity tables and list screens.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.customAction,
    this.padding = const EdgeInsets.all(32),
  });

  /// Primary headline (e.g. "No organizations found").
  final String title;

  /// Secondary guidance text.
  final String? message;

  /// Large icon displayed above the text.
  final IconData icon;

  /// Optional label for the CTA button.
  final String? actionLabel;

  /// Optional icon for the CTA button.
  final IconData? actionIcon;

  /// Action callback when CTA button is tapped.
  final VoidCallback? onAction;

  /// Custom action widget if a simple button is not enough.
  final Widget? customAction;

  /// Padding around the empty state content.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtleColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 56,
              color: subtleColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (customAction != null) ...[
              const SizedBox(height: 20),
              customAction!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: Icon(actionIcon ?? Icons.add, size: 18),
                label: Text(actionLabel!),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Clean, zero-padding switch list tile standardized for form dialogs and settings.
///
/// Features:
/// - Eliminates default inset padding so it aligns neatly with text fields.
/// - Supports title, optional subtitle, and active/inactive status styling.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title = 'Active',
    this.subtitle,
    this.enabled = true,
    this.contentPadding = EdgeInsets.zero,
  });

  /// Current switch state.
  final bool value;

  /// Callback when switched.
  final ValueChanged<bool>? onChanged;

  /// Primary label (e.g. "Active").
  final String title;

  /// Optional secondary description.
  final String? subtitle;

  /// Whether the switch is enabled.
  final bool enabled;

  /// Padding around the tile. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      contentPadding: contentPadding,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: enabled ? null : Theme.of(context).disabledColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            )
          : null,
    );
  }
}

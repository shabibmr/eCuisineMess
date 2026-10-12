import 'package:flutter/material.dart';

/// Standard status types supported across the eCuisine Mess module.
enum AppStatusType {
  active,
  inactive,
  expired,
  suspended,
  served,
  cancelled,
  locked,
  unsaved;

  /// Attempts to parse a raw string status into an [AppStatusType].
  static AppStatusType? tryParse(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    for (final val in AppStatusType.values) {
      if (val.name.toLowerCase() == normalized) {
        return val;
      }
    }
    // Common aliases
    if (normalized == 'act') return AppStatusType.active;
    if (normalized == 'inact') return AppStatusType.inactive;
    if (normalized == 'exp') return AppStatusType.expired;
    if (normalized == 'susp') return AppStatusType.suspended;
    if (normalized == 'canceled') return AppStatusType.cancelled;
    if (normalized == 'lock') return AppStatusType.locked;
    if (normalized == 'draft') return AppStatusType.unsaved;
    return null;
  }
}

/// A compact, unified badge for entity statuses across the Mess application.
///
/// Adheres strictly to Material 3 design tokens with subtle tinted backgrounds,
/// matching borders, and readable high-contrast text.
///
/// Usage:
/// ```dart
/// AppStatusBadge.active();
/// AppStatusBadge.inactive();
/// AppStatusBadge(type: AppStatusType.served);
/// AppStatusBadge.fromBool(isActive, activeLabel: 'Active', inactiveLabel: 'Inactive');
/// ```
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.type,
    this.label,
    this.icon,
    this.compact = false,
  });

  /// Factory helper for boolean active / inactive flags.
  factory AppStatusBadge.fromBool(
    bool isActive, {
    Key? key,
    String? activeLabel,
    String? inactiveLabel,
    bool compact = false,
  }) {
    return AppStatusBadge(
      key: key,
      type: isActive ? AppStatusType.active : AppStatusType.inactive,
      label: isActive ? activeLabel : inactiveLabel,
      compact: compact,
    );
  }

  /// Preset constructors
  const AppStatusBadge.active({Key? key, String? label, bool compact = false})
      : this(key: key, type: AppStatusType.active, label: label, compact: compact);

  const AppStatusBadge.inactive({Key? key, String? label, bool compact = false})
      : this(key: key, type: AppStatusType.inactive, label: label, compact: compact);

  const AppStatusBadge.expired({Key? key, String? label, bool compact = false})
      : this(key: key, type: AppStatusType.expired, label: label, compact: compact);

  const AppStatusBadge.suspended({Key? key, String? label, bool compact = false})
      : this(key: key, type: AppStatusType.suspended, label: label, compact: compact);

  const AppStatusBadge.served({Key? key, String? label, bool compact = false})
      : this(key: key, type: AppStatusType.served, label: label, compact: compact);

  const AppStatusBadge.cancelled({Key? key, String? label, bool compact = false})
      : this(key: key, type: AppStatusType.cancelled, label: label, compact: compact);

  const AppStatusBadge.locked({Key? key, String? label, bool compact = false})
      : this(key: key, type: AppStatusType.locked, label: label, compact: compact);

  const AppStatusBadge.unsaved({Key? key, String? label, bool compact = false})
      : this(key: key, type: AppStatusType.unsaved, label: label, compact: compact);

  final AppStatusType type;
  final String? label;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig(context, type);
    final displayText = label ?? config.defaultLabel;
    final displayIcon = icon ?? config.defaultIcon;

    final horizontalPadding = compact ? 6.0 : 8.0;
    final verticalPadding = compact ? 2.0 : 3.0;
    final fontSize = compact ? 11.0 : 12.0;
    final iconSize = compact ? 12.0 : 13.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (displayIcon != null) ...[
            Icon(
              displayIcon,
              size: iconSize,
              color: config.foregroundColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            displayText,
            style: TextStyle(
              color: config.foregroundColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeStyleConfig _resolveConfig(BuildContext context, AppStatusType type) {
    switch (type) {
      case AppStatusType.active:
        return const _BadgeStyleConfig(
          defaultLabel: 'Active',
          backgroundColor: Color(0xFFECFDF5), // Emerald 50
          borderColor: Color(0xFFA7F3D0),     // Emerald 200
          foregroundColor: Color(0xFF047857), // Emerald 700
          defaultIcon: Icons.check_circle_outline,
        );
      case AppStatusType.inactive:
        return const _BadgeStyleConfig(
          defaultLabel: 'Inactive',
          backgroundColor: Color(0xFFF1F5F9), // Slate 100
          borderColor: Color(0xFFCBD5E1),     // Slate 300
          foregroundColor: Color(0xFF475569), // Slate 600
          defaultIcon: Icons.remove_circle_outline,
        );
      case AppStatusType.expired:
        return const _BadgeStyleConfig(
          defaultLabel: 'Expired',
          backgroundColor: Color(0xFFFEF2F2), // Red 50
          borderColor: Color(0xFFFECACA),     // Red 200
          foregroundColor: Color(0xFFB91C1C), // Red 700
          defaultIcon: Icons.error_outline,
        );
      case AppStatusType.suspended:
        return const _BadgeStyleConfig(
          defaultLabel: 'Suspended',
          backgroundColor: Color(0xFFFFFBEB), // Amber 50
          borderColor: Color(0xFFFDE68A),     // Amber 200
          foregroundColor: Color(0xFFB45309), // Amber 700
          defaultIcon: Icons.pause_circle_outline,
        );
      case AppStatusType.served:
        return const _BadgeStyleConfig(
          defaultLabel: 'Served',
          backgroundColor: Color(0xFFEFF6FF), // Blue 50
          borderColor: Color(0xFFBFDBFE),     // Blue 200
          foregroundColor: Color(0xFF1D4ED8), // Blue 700
          defaultIcon: Icons.task_alt,
        );
      case AppStatusType.cancelled:
        return const _BadgeStyleConfig(
          defaultLabel: 'Cancelled',
          backgroundColor: Color(0xFFFEE2E2), // Rose 100
          borderColor: Color(0xFFFCA5A5),     // Rose 300
          foregroundColor: Color(0xFF991B1B), // Rose 800
          defaultIcon: Icons.cancel_outlined,
        );
      case AppStatusType.locked:
        return const _BadgeStyleConfig(
          defaultLabel: 'Locked',
          backgroundColor: Color(0xFFF3E8FF), // Purple 100
          borderColor: Color(0xFFDDD6FE),     // Purple 200
          foregroundColor: Color(0xFF6D28D9), // Purple 700
          defaultIcon: Icons.lock_outline,
        );
      case AppStatusType.unsaved:
        return const _BadgeStyleConfig(
          defaultLabel: 'Unsaved',
          backgroundColor: Color(0xFFFFF7ED), // Orange 50
          borderColor: Color(0xFFFED7AA),     // Orange 200
          foregroundColor: Color(0xFFC2410C), // Orange 700
          defaultIcon: Icons.edit_note,
        );
    }
  }
}

class _BadgeStyleConfig {
  const _BadgeStyleConfig({
    required this.defaultLabel,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    this.defaultIcon,
  });

  final String defaultLabel;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final IconData? defaultIcon;
}

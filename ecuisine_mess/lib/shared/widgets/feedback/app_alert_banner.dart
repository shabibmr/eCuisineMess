import 'package:flutter/material.dart';

/// Severity types for [AppAlertBanner].
enum AppAlertSeverity {
  error,
  warning,
  info,
  success,
}

/// Unified in-page notification banner for errors, warnings, info, and success messages.
///
/// Designed to replace and unify ad-hoc banners (such as `ErrorBanner`,
/// `RejectBanner`, `MenuPastDateBanner`, and `MenuMealLockedBanner`).
class AppAlertBanner extends StatelessWidget {
  const AppAlertBanner({
    super.key,
    required this.message,
    this.title,
    this.severity = AppAlertSeverity.error,
    this.icon,
    this.action,
    this.onDismiss,
    this.visible = true,
    this.margin,
  });

  /// Preset for error banners.
  const AppAlertBanner.error({
    Key? key,
    required String message,
    String? title,
    IconData? icon,
    Widget? action,
    VoidCallback? onDismiss,
    bool visible = true,
    EdgeInsetsGeometry? margin,
  }) : this(
          key: key,
          message: message,
          title: title,
          severity: AppAlertSeverity.error,
          icon: icon,
          action: action,
          onDismiss: onDismiss,
          visible: visible,
          margin: margin,
        );

  /// Preset for warning banners.
  const AppAlertBanner.warning({
    Key? key,
    required String message,
    String? title,
    IconData? icon,
    Widget? action,
    VoidCallback? onDismiss,
    bool visible = true,
    EdgeInsetsGeometry? margin,
  }) : this(
          key: key,
          message: message,
          title: title,
          severity: AppAlertSeverity.warning,
          icon: icon,
          action: action,
          onDismiss: onDismiss,
          visible: visible,
          margin: margin,
        );

  /// Preset for info banners.
  const AppAlertBanner.info({
    Key? key,
    required String message,
    String? title,
    IconData? icon,
    Widget? action,
    VoidCallback? onDismiss,
    bool visible = true,
    EdgeInsetsGeometry? margin,
  }) : this(
          key: key,
          message: message,
          title: title,
          severity: AppAlertSeverity.info,
          icon: icon,
          action: action,
          onDismiss: onDismiss,
          visible: visible,
          margin: margin,
        );

  /// Preset for success banners.
  const AppAlertBanner.success({
    Key? key,
    required String message,
    String? title,
    IconData? icon,
    Widget? action,
    VoidCallback? onDismiss,
    bool visible = true,
    EdgeInsetsGeometry? margin,
  }) : this(
          key: key,
          message: message,
          title: title,
          severity: AppAlertSeverity.success,
          icon: icon,
          action: action,
          onDismiss: onDismiss,
          visible: visible,
          margin: margin,
        );

  final String message;
  final String? title;
  final AppAlertSeverity severity;
  final IconData? icon;
  final Widget? action;
  final VoidCallback? onDismiss;
  final bool visible;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final config = _resolveConfig(context);
    final displayIcon = icon ?? config.defaultIcon;

    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            displayIcon,
            color: config.iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null && title!.isNotEmpty)
                  Text(
                    title!,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: config.titleColor,
                    ),
                  ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: config.messageColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 12),
            action!,
          ],
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: config.iconColor),
              onPressed: onDismiss,
              tooltip: 'Dismiss',
            ),
          ],
        ],
      ),
    );
  }

  _AlertColors _resolveConfig(BuildContext context) {
    switch (severity) {
      case AppAlertSeverity.error:
        return const _AlertColors(
          backgroundColor: Color(0xFFFEF2F2),
          borderColor: Color(0xFFFECACA),
          iconColor: Color(0xFFDC2626),
          titleColor: Color(0xFF991B1B),
          messageColor: Color(0xFF7F1D1D),
          defaultIcon: Icons.error_outline,
        );
      case AppAlertSeverity.warning:
        return const _AlertColors(
          backgroundColor: Color(0xFFFFFBEB),
          borderColor: Color(0xFFFDE68A),
          iconColor: Color(0xFFD97706),
          titleColor: Color(0xFF92400E),
          messageColor: Color(0xFF78350F),
          defaultIcon: Icons.warning_amber_rounded,
        );
      case AppAlertSeverity.info:
        return const _AlertColors(
          backgroundColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
          iconColor: Color(0xFF2563EB),
          titleColor: Color(0xFF1E40AF),
          messageColor: Color(0xFF1E3A8A),
          defaultIcon: Icons.info_outline,
        );
      case AppAlertSeverity.success:
        return const _AlertColors(
          backgroundColor: Color(0xFFECFDF5),
          borderColor: Color(0xFFA7F3D0),
          iconColor: Color(0xFF059669),
          titleColor: Color(0xFF065F46),
          messageColor: Color(0xFF064E3B),
          defaultIcon: Icons.check_circle_outline,
        );
    }
  }
}

class _AlertColors {
  const _AlertColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.titleColor,
    required this.messageColor,
    required this.defaultIcon,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color titleColor;
  final Color messageColor;
  final IconData defaultIcon;
}

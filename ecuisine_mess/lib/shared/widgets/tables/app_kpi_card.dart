import 'package:flutter/material.dart';

/// A Material 3 KPI / Stat card with a colored accent border and tabular figures.
///
/// Designed for dashboard metrics, summary counters, and analytical tiles.
class AppKpiCard extends StatelessWidget {
  const AppKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accent,
    this.caption,
    this.onTap,
    this.margin = EdgeInsets.zero,
    this.padding = const EdgeInsets.all(14),
    this.accentWidth = 3.0,
    this.valueStyle,
  });

  /// Metric title or label (e.g. "Total served", "Total Sales").
  final String label;

  /// Numeric or string metric value (e.g. 142, "1,240", "AED 450").
  final Object value;

  /// Optional icon displayed in top right.
  final IconData? icon;

  /// Accent color for the left border and icon. Defaults to [ColorScheme.primary].
  final Color? accent;

  /// Optional caption/subtitle beneath the metric value.
  final String? caption;

  /// Optional tap callback for clickable KPI tiles.
  final VoidCallback? onTap;

  /// Outer card margin. Defaults to [EdgeInsets.zero].
  final EdgeInsetsGeometry margin;

  /// Inner padding. Defaults to 14px on all sides.
  final EdgeInsetsGeometry padding;

  /// Left accent border width. Defaults to 3.0.
  final double accentWidth;

  /// Optional custom style for the metric value text.
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveAccent = accent ?? scheme.primary;

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: effectiveAccent, width: accentWidth),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 16, color: effectiveAccent),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: valueStyle ??
                const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: content,
            )
          : content,
    );
  }
}

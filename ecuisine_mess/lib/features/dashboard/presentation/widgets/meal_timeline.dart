import 'package:ecuisine_mess/features/dashboard/presentation/utils/meal_style.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/utils/meal_timeline_logic.dart';
import 'package:ecuisine_mess/shared/cubit/meal_clock_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Service windows with a live now-marker. Ranges and tick labels come from
/// [windows]; the marker follows [MealClockCubit].
class MealTimeline extends StatelessWidget {
  const MealTimeline({super.key, required this.windows});

  final List<TimelineWindow> windows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (windows.isEmpty) {
      return Text(
        'No meal windows configured',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return BlocBuilder<MealClockCubit, String>(
      builder: (context, clock) {
        final now = clockToMinutes(clock);
        final bounds = timelineBounds(windows);
        final span = (bounds.end - bounds.start).toDouble();
        final status = timelineStatus(windows, now);
        final tickMinutes = {
          for (final w in windows) ...[w.startMinutes, w.endMinutes],
        }.toList()..sort();

        double frac(num minutes) =>
            ((minutes - bounds.start) / span).clamp(0.0, 1.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(status: status),
                const Spacer(),
                Text(
                  clock.substring(0, clock.length >= 5 ? 5 : clock.length),
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                return SizedBox(
                  height: 22,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                      for (final win in windows)
                        Positioned(
                          left: frac(win.startMinutes) * w,
                          width:
                              (frac(win.endMinutes) - frac(win.startMinutes)) *
                              w,
                          top: 0,
                          bottom: 0,
                          child: Tooltip(
                            message:
                                '${win.name}: ${win.startLabel} - ${win.endLabel}',
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: MealStyle.of(
                                  win.mealType,
                                ).color.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: frac(now) * w - 2,
                        width: 4,
                        top: -3,
                        bottom: -3,
                        child: DecoratedBox(
                          key: const ValueKey('timeline-now-marker'),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, c) {
                const labelW = 40.0;
                return SizedBox(
                  height: 14,
                  child: Stack(
                    children: [
                      for (final t in tickMinutes)
                        Positioned(
                          left: (frac(t) * c.maxWidth - labelW / 2).clamp(
                            0.0,
                            c.maxWidth - labelW,
                          ),
                          width: labelW,
                          child: Text(
                            formatMinutes(t),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TimelineStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final win = status.window;
    final (text, color) = switch (status.kind) {
      TimelineStatusKind.active => (
        'Active: ${win!.name} (until ${win.endLabel})',
        MealStyle.of(win.mealType).color,
      ),
      TimelineStatusKind.next => (
        'Next: ${win!.name} in ${formatDuration(status.minutesUntil)}',
        scheme.outline,
      ),
      TimelineStatusKind.closed => ('Service Closed', scheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';
import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';
import 'package:equatable/equatable.dart';

/// One meal's service window on the timeline, merged across cuisines
/// (earliest start, latest end).
class TimelineWindow extends Equatable {
  const TimelineWindow({
    required this.mealType,
    required this.name,
    required this.startMinutes,
    required this.endMinutes,
  });

  final String mealType;
  final String name;
  final int startMinutes;
  final int endMinutes;

  String get startLabel => formatMinutes(startMinutes);
  String get endLabel => formatMinutes(endMinutes);

  @override
  List<Object?> get props => [mealType, name, startMinutes, endMinutes];
}

enum TimelineStatusKind { active, next, closed }

class TimelineStatus extends Equatable {
  const TimelineStatus(this.kind, {this.window, this.minutesUntil = 0});

  final TimelineStatusKind kind;
  final TimelineWindow? window;

  /// Minutes until [window] starts; only meaningful for [TimelineStatusKind.next].
  final int minutesUntil;

  @override
  List<Object?> get props => [kind, window, minutesUntil];
}

/// Parses `HH:mm` or `HH:mm:ss` into minutes after midnight.
int? parseMinutes(String value) {
  final parts = value.trim().split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// Minutes (with seconds as a fraction) from a `HH:mm:ss` clock string.
double clockToMinutes(String clock) {
  final parts = clock.split(':');
  final h = int.tryParse(parts[0]) ?? 0;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  final s = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
  return h * 60 + m + s / 60;
}

String formatMinutes(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h:$m';
}

String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

/// Builds timeline windows from meal-time settings. When none are available,
/// falls back to the summary's [fallback] windows (current / next).
List<TimelineWindow> buildTimelineWindows(
  List<MealTime> mealTimes, {
  List<MealWindow?> fallback = const [],
}) {
  final raw = mealTimes.isNotEmpty
      ? [
          for (final m in mealTimes)
            (m.mealType, m.name, m.startTime, m.endTime),
        ]
      : [
          for (final w in fallback)
            if (w != null) (w.mealType, w.name, w.startTime, w.endTime),
        ];

  final byMeal = <String, TimelineWindow>{};
  for (final (mealType, name, start, end) in raw) {
    final s = parseMinutes(start);
    final e = parseMinutes(end);
    if (s == null || e == null || e <= s) continue;
    final existing = byMeal[mealType];
    byMeal[mealType] = existing == null
        ? TimelineWindow(
            mealType: mealType,
            name: name,
            startMinutes: s,
            endMinutes: e,
          )
        : TimelineWindow(
            mealType: mealType,
            name: existing.name,
            startMinutes: s < existing.startMinutes ? s : existing.startMinutes,
            endMinutes: e > existing.endMinutes ? e : existing.endMinutes,
          );
  }
  return byMeal.values.toList()
    ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
}

/// Visible range: first start rounded down to the hour, last end rounded up
/// to the half hour.
({int start, int end}) timelineBounds(List<TimelineWindow> windows) {
  var start = windows.first.startMinutes;
  var end = windows.first.endMinutes;
  for (final w in windows) {
    if (w.startMinutes < start) start = w.startMinutes;
    if (w.endMinutes > end) end = w.endMinutes;
  }
  start = (start ~/ 60) * 60;
  end = ((end + 29) ~/ 30) * 30;
  return (start: start, end: end > 1440 ? 1440 : end);
}

/// Active window now, else the next one today, else closed.
TimelineStatus timelineStatus(List<TimelineWindow> windows, double nowMinutes) {
  for (final w in windows) {
    if (nowMinutes >= w.startMinutes && nowMinutes < w.endMinutes) {
      return TimelineStatus(TimelineStatusKind.active, window: w);
    }
  }
  for (final w in windows) {
    if (nowMinutes < w.startMinutes) {
      return TimelineStatus(
        TimelineStatusKind.next,
        window: w,
        minutesUntil: (w.startMinutes - nowMinutes).ceil(),
      );
    }
  }
  return const TimelineStatus(TimelineStatusKind.closed);
}

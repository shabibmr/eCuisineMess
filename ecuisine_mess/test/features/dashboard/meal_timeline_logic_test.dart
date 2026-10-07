import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/utils/meal_timeline_logic.dart';
import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

MealTime mt(String type, String start, String end, {String cuisine = 'c1'}) =>
    MealTime(
      id: '$cuisine$type',
      cuisineId: cuisine,
      mealType: type,
      name: type[0] + type.substring(1).toLowerCase(),
      startTime: start,
      endTime: end,
    );

void main() {
  final windows = buildTimelineWindows([
    mt('DINNER', '19:00:00', '22:30:00'),
    mt('BREAKFAST', '06:30:00', '10:00:00'),
    mt('LUNCH', '12:00:00', '15:00:00'),
  ]);

  test('windows are sorted and parsed', () {
    expect(windows.map((w) => w.mealType), ['BREAKFAST', 'LUNCH', 'DINNER']);
    expect(windows.first.startLabel, '06:30');
  });

  test('same meal across cuisines merges to the widest range', () {
    final merged = buildTimelineWindows([
      mt('LUNCH', '12:00', '14:00', cuisine: 'a'),
      mt('LUNCH', '11:30', '13:00', cuisine: 'b'),
    ]);
    expect(merged, hasLength(1));
    expect(merged.single.startMinutes, 11 * 60 + 30);
    expect(merged.single.endMinutes, 14 * 60);
  });

  test('falls back to summary windows when no meal times', () {
    const w = MealWindow(
      name: 'Lunch',
      mealType: 'LUNCH',
      startTime: '12:00:00',
      endTime: '15:00:00',
    );
    expect(buildTimelineWindows([], fallback: [w, null]), hasLength(1));
    expect(buildTimelineWindows([]), isEmpty);
  });

  test('bounds come from the data', () {
    final b = timelineBounds(windows);
    expect(b.start, 6 * 60);
    expect(b.end, 22 * 60 + 30);
  });

  test('active / next / closed', () {
    final active = timelineStatus(windows, 13 * 60.0);
    expect(active.kind, TimelineStatusKind.active);
    expect(active.window!.endLabel, '15:00');

    final next = timelineStatus(windows, 16 * 60.0 + 10);
    expect(next.kind, TimelineStatusKind.next);
    expect(next.window!.mealType, 'DINNER');
    expect(formatDuration(next.minutesUntil), '2h 50m');

    expect(timelineStatus(windows, 23 * 60.0).kind, TimelineStatusKind.closed);
    expect(timelineStatus(windows, 5 * 60.0).kind, TimelineStatusKind.next);
  });

  test('clock parsing', () {
    expect(clockToMinutes('12:30:30'), 12 * 60 + 30.5);
    expect(parseMinutes('7:05'), 425);
    expect(parseMinutes('bad'), isNull);
  });
}

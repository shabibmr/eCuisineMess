import 'package:ecuisine_mess/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

DashboardSummary parse(Map<String, dynamic> json) =>
    DashboardSummaryModel.fromJson(json).toEntity();

void main() {
  test('parses a full response', () {
    final s = parse({
      'server_time': '2026-10-06 12:30:00',
      'current_meal': 'LUNCH',
      'next_meal': 'DINNER',
      'current_window': {
        'name': 'Lunch',
        'meal_type': 'LUNCH',
        'start_time': '12:00:00',
        'end_time': '15:00:00',
      },
      'next_window': {
        'name': 'Dinner',
        'meal_type': 'DINNER',
        'start_time': '19:00:00',
        'end_time': '22:00:00',
      },
      'served_today': {'BREAKFAST': 5, 'LUNCH': 7, 'DINNER': 0, 'total': 12},
      'menu_readiness': [
        {
          'cuisine_id': 'c1',
          'cuisine_name': 'North Indian',
          'status': 'PARTIAL',
          'filled_count': 2,
          'total_slots': 3,
          'slots': {'BREAKFAST': true, 'LUNCH': true, 'DINNER': false},
        },
      ],
      'served_by_cuisine': [
        {
          'cuisine_id': 'c1',
          'cuisine_name': 'North Indian',
          'BREAKFAST': 5,
          'LUNCH': 7,
          'DINNER': 0,
          'total': 12,
        },
      ],
    });

    expect(s.serverTime, DateTime(2026, 10, 6, 12, 30));
    expect(s.currentMeal, 'LUNCH');
    expect(s.currentWindow?.startTime, '12:00:00');
    expect(s.nextWindow?.name, 'Dinner');
    expect(s.servedToday.total, 12);
    final r = s.menuReadiness.single;
    expect(r.status, ReadinessStatus.partial);
    expect(r.breakfast, isTrue);
    expect(r.dinner, isFalse);
    expect(s.servedByCuisine.single.lunch, 7);
  });

  test('null windows and meals (Service Closed, no windows configured)', () {
    final s = parse({
      'current_meal': null,
      'next_meal': null,
      'current_window': null,
      'next_window': null,
      'served_today': {'BREAKFAST': 0, 'LUNCH': 0, 'DINNER': 0, 'total': 0},
      'menu_readiness': <dynamic>[],
    });
    expect(s.currentMeal, isNull);
    expect(s.currentWindow, isNull);
    expect(s.nextWindow, isNull);
    expect(s.menuReadiness, isEmpty);
  });

  test('numbers as strings / decimals', () {
    final s = parse({
      'served_today': {'BREAKFAST': '3', 'LUNCH': '4.0', 'DINNER': 1.0},
      'served_by_cuisine': [
        {'cuisine_id': 7, 'cuisine_name': 'X', 'BREAKFAST': '2', 'total': '2'},
      ],
      'menu_readiness': [
        {
          'cuisine_id': 'c',
          'cuisine_name': 'X',
          'status': 'FULL',
          'filled_count': '3',
          'total_slots': '3',
          'BREAKFAST': 1,
          'LUNCH': '1',
          'DINNER': true,
        },
      ],
    });
    expect(s.servedToday.breakfast, 3);
    expect(s.servedToday.lunch, 4);
    expect(s.servedToday.dinner, 1);
    expect(s.servedToday.total, 8, reason: 'derived when total is absent');
    expect(s.servedByCuisine.single.cuisineId, '7');
    expect(s.servedByCuisine.single.total, 2);
    final r = s.menuReadiness.single;
    expect(r.filledCount, 3);
    expect(r.lunch && r.dinner && r.breakfast, isTrue);
  });

  test('missing served_by_cuisine and served_today parse to empty/zero', () {
    final s = parse({'current_meal': 'LUNCH'});
    expect(s.servedByCuisine, isEmpty);
    expect(s.servedToday, ServedToday.zero);
    expect(s.serverTime, isNull);
  });

  test('status derived from filled_count when missing or unknown', () {
    ReadinessStatus status(Map<String, dynamic> row) => parse({
      'menu_readiness': [
        {'cuisine_id': 'c', 'cuisine_name': 'X', ...row},
      ],
    }).menuReadiness.single.status;

    expect(status({'filled_count': 0}), ReadinessStatus.empty);
    expect(status({'filled_count': 1}), ReadinessStatus.partial);
    expect(status({'filled_count': 3, 'status': '??'}), ReadinessStatus.full);
  });
}

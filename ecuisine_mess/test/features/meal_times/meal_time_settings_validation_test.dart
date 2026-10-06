import 'package:ecuisine_mess/features/meal_times/presentation/bloc/meal_time_settings_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MealTimeRowEdit row({
    required String id,
    required String start,
    required String end,
    bool active = true,
  }) {
    return MealTimeRowEdit(
      id: id,
      mealType: id,
      name: id,
      startTime: start,
      endTime: end,
      isActive: active,
    );
  }

  test('flags start >= end', () {
    final result = MealTimeSettingsBloc.validateRows([
      row(id: 'b', start: '10:00:00', end: '09:00:00'),
    ]);
    expect(result.single.validationError, 'Start must be before end');
  });

  test('flags overlapping active windows', () {
    final result = MealTimeSettingsBloc.validateRows([
      row(id: 'b', start: '07:00:00', end: '11:00:00'),
      row(id: 'l', start: '10:30:00', end: '15:00:00'),
    ]);
    expect(result[0].validationError, 'Overlaps another window');
    expect(result[1].validationError, 'Overlaps another window');
  });

  test('inactive windows do not overlap-check', () {
    final result = MealTimeSettingsBloc.validateRows([
      row(id: 'b', start: '07:00:00', end: '11:00:00'),
      row(id: 'l', start: '10:30:00', end: '15:00:00', active: false),
    ]);
    expect(result[0].validationError, isNull);
    expect(result[1].validationError, isNull);
  });
}

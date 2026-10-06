import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';

abstract interface class MealTimeRepository {
  Future<List<MealTime>> getMealTimes({String? cuisineId});

  Future<void> saveMealTime({
    required String id,
    String? name,
    String? startTime,
    String? endTime,
    bool? isActive,
  });
}

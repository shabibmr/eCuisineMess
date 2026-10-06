import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/meal_times/data/datasources/meal_time_remote_datasource.dart';
import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';
import 'package:ecuisine_mess/features/meal_times/domain/repositories/meal_time_repository.dart';

class MealTimeRepositoryImpl implements MealTimeRepository {
  MealTimeRepositoryImpl(this._remote);

  final MealTimeRemoteDataSource _remote;

  @override
  Future<List<MealTime>> getMealTimes({String? cuisineId}) async {
    try {
      final list = await _remote.getMealTimes(cuisineId: cuisineId);
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> saveMealTime({
    required String id,
    String? name,
    String? startTime,
    String? endTime,
    bool? isActive,
  }) async {
    try {
      await _remote.updateMealTime(
        id: id,
        name: name,
        startTime: startTime,
        endTime: endTime,
        isActive: isActive,
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}

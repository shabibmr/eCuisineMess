import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';
import 'package:ecuisine_mess/features/meal_times/domain/repositories/meal_time_repository.dart';
import 'package:equatable/equatable.dart';

class GetMealTimes extends UseCase<List<MealTime>, GetMealTimesParams> {
  GetMealTimes(this._repository);

  final MealTimeRepository _repository;

  @override
  Future<List<MealTime>> call(GetMealTimesParams params) {
    return _repository.getMealTimes(cuisineId: params.cuisineId);
  }
}

class GetMealTimesParams extends Equatable {
  const GetMealTimesParams({this.cuisineId});

  final String? cuisineId;

  @override
  List<Object?> get props => [cuisineId];
}

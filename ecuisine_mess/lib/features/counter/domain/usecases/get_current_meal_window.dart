import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';
import 'package:ecuisine_mess/features/counter/domain/repositories/counter_repository.dart';
import 'package:equatable/equatable.dart';

class GetCurrentMealWindow
    extends UseCase<MealWindow?, GetCurrentMealWindowParams> {
  GetCurrentMealWindow(this._repository);

  final CounterRepository _repository;

  @override
  Future<MealWindow?> call(GetCurrentMealWindowParams params) {
    return _repository.getCurrentMealWindow(cuisineId: params.cuisineId);
  }
}

class GetCurrentMealWindowParams extends Equatable {
  const GetCurrentMealWindowParams({this.cuisineId});

  final String? cuisineId;

  @override
  List<Object?> get props => [cuisineId];
}

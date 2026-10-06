import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/meal_times/domain/repositories/meal_time_repository.dart';
import 'package:equatable/equatable.dart';

class SaveMealTime extends UseCase<void, SaveMealTimeParams> {
  SaveMealTime(this._repository);

  final MealTimeRepository _repository;

  @override
  Future<void> call(SaveMealTimeParams params) {
    return _repository.saveMealTime(
      id: params.id,
      name: params.name,
      startTime: params.startTime,
      endTime: params.endTime,
      isActive: params.isActive,
    );
  }
}

class SaveMealTimeParams extends Equatable {
  const SaveMealTimeParams({
    required this.id,
    this.name,
    this.startTime,
    this.endTime,
    this.isActive,
  });

  final String id;
  final String? name;
  final String? startTime;
  final String? endTime;
  final bool? isActive;

  @override
  List<Object?> get props => [id, name, startTime, endTime, isActive];
}

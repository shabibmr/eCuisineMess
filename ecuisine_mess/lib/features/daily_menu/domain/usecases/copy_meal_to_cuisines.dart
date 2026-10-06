import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/copy_meal_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/repositories/daily_menu_repository.dart';
import 'package:equatable/equatable.dart';

class CopyMealToCuisines
    extends UseCase<CopyMealResult, CopyMealToCuisinesParams> {
  CopyMealToCuisines(this._repository);

  final DailyMenuRepository _repository;

  @override
  Future<CopyMealResult> call(CopyMealToCuisinesParams params) {
    return _repository.copyMeal(
      menuDate: params.menuDate,
      fromCuisineId: params.fromCuisineId,
      mealType: params.mealType,
      toCuisineIds: params.toCuisineIds,
    );
  }
}

class CopyMealToCuisinesParams extends Equatable {
  const CopyMealToCuisinesParams({
    required this.menuDate,
    required this.fromCuisineId,
    required this.mealType,
    required this.toCuisineIds,
  });

  final String menuDate;
  final String fromCuisineId;
  final String mealType;
  final List<String> toCuisineIds;

  @override
  List<Object?> get props =>
      [menuDate, fromCuisineId, mealType, toCuisineIds];
}

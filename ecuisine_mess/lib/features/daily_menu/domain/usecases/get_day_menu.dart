import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/repositories/daily_menu_repository.dart';
import 'package:equatable/equatable.dart';

/// Loads all slots for a date (optionally filtered by cuisine / meal).
class GetDayMenu extends UseCase<List<DailyMenu>, GetDayMenuParams> {
  GetDayMenu(this._repository);

  final DailyMenuRepository _repository;

  @override
  Future<List<DailyMenu>> call(GetDayMenuParams params) {
    return _repository.getMenus(
      menuDate: params.menuDate,
      cuisineId: params.cuisineId,
      mealType: params.mealType,
    );
  }
}

class GetDayMenuParams extends Equatable {
  const GetDayMenuParams({
    required this.menuDate,
    this.cuisineId,
    this.mealType,
  });

  final String menuDate;
  final String? cuisineId;
  final String? mealType;

  @override
  List<Object?> get props => [menuDate, cuisineId, mealType];
}

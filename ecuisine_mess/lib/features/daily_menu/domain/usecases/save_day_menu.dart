import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/day_menu_slot_input.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/save_day_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/repositories/daily_menu_repository.dart';
import 'package:equatable/equatable.dart';

class SaveDayMenu extends UseCase<SaveDayResult, SaveDayMenuParams> {
  SaveDayMenu(this._repository);

  final DailyMenuRepository _repository;

  @override
  Future<SaveDayResult> call(SaveDayMenuParams params) {
    return _repository.saveDay(
      menuDate: params.menuDate,
      menus: params.menus,
    );
  }
}

class SaveDayMenuParams extends Equatable {
  const SaveDayMenuParams({
    required this.menuDate,
    required this.menus,
  });

  final String menuDate;
  final List<DayMenuSlotInput> menus;

  @override
  List<Object?> get props => [menuDate, menus];
}

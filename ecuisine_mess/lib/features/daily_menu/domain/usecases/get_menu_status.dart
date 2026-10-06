import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/cuisine_menu_status.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/repositories/daily_menu_repository.dart';
import 'package:equatable/equatable.dart';

class GetMenuStatus extends UseCase<MenuDayStatus, GetMenuStatusParams> {
  GetMenuStatus(this._repository);

  final DailyMenuRepository _repository;

  @override
  Future<MenuDayStatus> call(GetMenuStatusParams params) {
    return _repository.getMenuStatus(menuDate: params.menuDate);
  }
}

class GetMenuStatusParams extends Equatable {
  const GetMenuStatusParams({this.menuDate});

  final String? menuDate;

  @override
  List<Object?> get props => [menuDate];
}

import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/menu_history_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/repositories/daily_menu_repository.dart';
import 'package:equatable/equatable.dart';

class GetMenuHistory extends UseCase<MenuHistoryResult, GetMenuHistoryParams> {
  GetMenuHistory(this._repository);

  final DailyMenuRepository _repository;

  @override
  Future<MenuHistoryResult> call(GetMenuHistoryParams params) {
    return _repository.getMenuHistory(
      fromDate: params.fromDate,
      toDate: params.toDate,
      cuisineId: params.cuisineId,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetMenuHistoryParams extends Equatable {
  const GetMenuHistoryParams({
    this.fromDate,
    this.toDate,
    this.cuisineId,
    this.limit = 50,
    this.offset = 0,
  });

  final String? fromDate;
  final String? toDate;
  final String? cuisineId;
  final int limit;
  final int offset;

  @override
  List<Object?> get props => [fromDate, toDate, cuisineId, limit, offset];
}

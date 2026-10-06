import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/copy_menus_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/repositories/daily_menu_repository.dart';
import 'package:equatable/equatable.dart';

class CopyFromDate extends UseCase<CopyMenusResult, CopyFromDateParams> {
  CopyFromDate(this._repository);

  final DailyMenuRepository _repository;

  @override
  Future<CopyMenusResult> call(CopyFromDateParams params) {
    return _repository.copyMenus(
      fromDate: params.fromDate,
      toDate: params.toDate,
      overwrite: params.overwrite,
    );
  }
}

class CopyFromDateParams extends Equatable {
  const CopyFromDateParams({
    required this.fromDate,
    required this.toDate,
    this.overwrite = false,
  });

  final String fromDate;
  final String toDate;
  final bool overwrite;

  @override
  List<Object?> get props => [fromDate, toDate, overwrite];
}

import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/issued_bill.dart';
import 'package:ecuisine_mess/features/counter/domain/repositories/counter_repository.dart';
import 'package:equatable/equatable.dart';

class IssueToken extends UseCase<IssuedBill, IssueTokenParams> {
  IssueToken(this._repository);

  final CounterRepository _repository;

  @override
  Future<IssuedBill> call(IssueTokenParams params) {
    return _repository.issueToken(
      memberId: params.memberId,
      mealType: params.mealType,
      isOverride: params.isOverride,
      overrideBy: params.overrideBy,
      overrideReason: params.overrideReason,
    );
  }
}

class IssueTokenParams extends Equatable {
  const IssueTokenParams({
    required this.memberId,
    required this.mealType,
    this.isOverride = false,
    this.overrideBy,
    this.overrideReason,
  });

  final String memberId;
  final String mealType;
  final bool isOverride;
  final String? overrideBy;
  final String? overrideReason;

  @override
  List<Object?> get props =>
      [memberId, mealType, isOverride, overrideBy, overrideReason];
}

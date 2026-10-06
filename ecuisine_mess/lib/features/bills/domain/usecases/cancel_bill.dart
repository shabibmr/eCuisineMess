import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/bills/domain/repositories/bill_repository.dart';
import 'package:equatable/equatable.dart';

class CancelBill extends UseCase<void, CancelBillParams> {
  CancelBill(this._repository);

  final BillRepository _repository;

  @override
  Future<void> call(CancelBillParams params) {
    return _repository.cancelBill(
      id: params.id,
      reason: params.reason,
      cancelledBy: params.cancelledBy,
    );
  }
}

class CancelBillParams extends Equatable {
  const CancelBillParams({
    required this.id,
    required this.reason,
    required this.cancelledBy,
  });

  final String id;
  final String reason;
  final String cancelledBy;

  @override
  List<Object?> get props => [id, reason, cancelledBy];
}

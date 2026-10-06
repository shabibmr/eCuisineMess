import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/bills/domain/entities/bill.dart';
import 'package:ecuisine_mess/features/bills/domain/repositories/bill_repository.dart';
import 'package:equatable/equatable.dart';

class GetBill extends UseCase<Bill, GetBillParams> {
  GetBill(this._repository);

  final BillRepository _repository;

  @override
  Future<Bill> call(GetBillParams params) => _repository.getBill(params.id);
}

class GetBillParams extends Equatable {
  const GetBillParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

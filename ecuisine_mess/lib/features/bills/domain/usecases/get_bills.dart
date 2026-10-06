import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/bills/domain/entities/bill.dart';
import 'package:ecuisine_mess/features/bills/domain/repositories/bill_repository.dart';
import 'package:equatable/equatable.dart';

class GetBills extends UseCase<List<Bill>, GetBillsParams> {
  GetBills(this._repository);

  final BillRepository _repository;

  @override
  Future<List<Bill>> call(GetBillsParams params) {
    return _repository.getBills(
      billDate: params.billDate,
      fromDate: params.fromDate,
      toDate: params.toDate,
      cuisineId: params.cuisineId,
      memberId: params.memberId,
      status: params.status,
      mealType: params.mealType,
      search: params.search,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class GetBillsParams extends Equatable {
  const GetBillsParams({
    this.billDate,
    this.fromDate,
    this.toDate,
    this.cuisineId,
    this.memberId,
    this.status,
    this.mealType,
    this.search,
    this.limit = 100,
    this.offset = 0,
  });

  final String? billDate;
  final String? fromDate;
  final String? toDate;
  final String? cuisineId;
  final String? memberId;
  final String? status;
  final String? mealType;
  final String? search;
  final int limit;
  final int offset;

  @override
  List<Object?> get props => [
        billDate,
        fromDate,
        toDate,
        cuisineId,
        memberId,
        status,
        mealType,
        search,
        limit,
        offset,
      ];
}

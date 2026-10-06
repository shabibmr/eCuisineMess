import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/bills/data/datasources/bill_remote_datasource.dart';
import 'package:ecuisine_mess/features/bills/domain/entities/bill.dart';
import 'package:ecuisine_mess/features/bills/domain/repositories/bill_repository.dart';

class BillRepositoryImpl implements BillRepository {
  BillRepositoryImpl(this._remote);

  final BillRemoteDataSource _remote;

  @override
  Future<List<Bill>> getBills({
    String? billDate,
    String? fromDate,
    String? toDate,
    String? cuisineId,
    String? memberId,
    String? status,
    String? mealType,
    String? search,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final list = await _remote.getBills(
        billDate: billDate,
        fromDate: fromDate,
        toDate: toDate,
        cuisineId: cuisineId,
        memberId: memberId,
        status: status,
        mealType: mealType,
        search: search,
        limit: limit,
        offset: offset,
      );
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Bill> getBill(String id) async {
    try {
      final model = await _remote.getBill(id);
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> cancelBill({
    required String id,
    required String reason,
    required String cancelledBy,
  }) async {
    try {
      await _remote.cancelBill(
        id: id,
        reason: reason,
        cancelledBy: cancelledBy,
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}

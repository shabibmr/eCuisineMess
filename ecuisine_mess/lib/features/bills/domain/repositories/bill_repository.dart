import 'package:ecuisine_mess/features/bills/domain/entities/bill.dart';

abstract interface class BillRepository {
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
  });

  Future<Bill> getBill(String id);

  Future<void> cancelBill({
    required String id,
    required String reason,
    required String cancelledBy,
  });
}

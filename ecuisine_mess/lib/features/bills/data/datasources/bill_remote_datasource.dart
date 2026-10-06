import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/bills/data/models/bill_model.dart';

abstract interface class BillRemoteDataSource {
  Future<List<BillModel>> getBills({
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

  Future<BillModel> getBill(String id);

  Future<void> cancelBill({
    required String id,
    required String reason,
    required String cancelledBy,
  });
}

class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  BillRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<BillModel>> getBills({
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
      final query = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (billDate != null && billDate.isNotEmpty) {
        query['bill_date'] = billDate;
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        query['from_date'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) query['to_date'] = toDate;
      if (cuisineId != null && cuisineId.isNotEmpty) {
        query['cuisine_id'] = cuisineId;
      }
      if (memberId != null && memberId.isNotEmpty) {
        query['member_id'] = memberId;
      }
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (mealType != null && mealType.isNotEmpty) {
        query['meal_type'] = mealType;
      }
      if (search != null && search.isNotEmpty) query['search'] = search;

      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.bills,
        queryParameters: query,
      );
      return (res.data ?? [])
          .map(
            (e) => BillModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<BillModel> getBill(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.bill(id),
      );
      return BillModel.fromJson(
        Map<String, dynamic>.from(res.data ?? const {}),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<void> cancelBill({
    required String id,
    required String reason,
    required String cancelledBy,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.billCancel(id),
        data: {'reason': reason, 'cancelled_by': cancelledBy},
      );
      final data = res.data;
      if (data != null && data['success'] == false) {
        throw AppException(
          data['message']?.toString() ?? 'Cancel failed',
        );
      }
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Object _unwrap(DioException e) {
    final err = e.error;
    if (err is AppException) return err;
    return AppException(e.message ?? 'Request failed');
  }
}

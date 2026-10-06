import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/counter/data/models/issued_bill_model.dart';
import 'package:ecuisine_mess/features/counter/data/models/meal_window_model.dart';
import 'package:ecuisine_mess/features/counter/data/models/tap_result_model.dart';

abstract interface class CounterRemoteDataSource {
  Future<MealWindowModel?> getCurrentMealWindow({String? cuisineId});

  Future<TapResultModel> tapRfid(String rfidTag);

  Future<IssuedBillModel> issueToken({
    required String memberId,
    required String mealType,
    bool isOverride = false,
    String? overrideBy,
    String? overrideReason,
  });
}

class CounterRemoteDataSourceImpl implements CounterRemoteDataSource {
  CounterRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<MealWindowModel?> getCurrentMealWindow({String? cuisineId}) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.mealTimesCurrent,
        queryParameters:
            cuisineId != null ? {'cuisine_id': cuisineId} : null,
      );
      final window = res.data?['window'];
      if (window is! Map) return null;
      return MealWindowModel.fromJson(Map<String, dynamic>.from(window));
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<TapResultModel> tapRfid(String rfidTag) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.counterTap,
        data: {'rfid_tag': rfidTag},
      );
      return TapResultModel.fromJson(
        Map<String, dynamic>.from(res.data ?? const {}),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<IssuedBillModel> issueToken({
    required String memberId,
    required String mealType,
    bool isOverride = false,
    String? overrideBy,
    String? overrideReason,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.counterIssueToken,
        data: {
          'member_id': memberId,
          'meal_type': mealType,
          'is_override': isOverride ? 1 : 0,
          'override_by': overrideBy,
          'override_reason': overrideReason,
        },
      );
      final data = Map<String, dynamic>.from(res.data ?? const {});
      if (data['success'] != true) {
        throw AppException(
          data['message']?.toString() ?? 'Failed to issue token',
        );
      }
      final bill = data['bill'];
      if (bill is! Map) {
        throw const AppException('Issue token response missing bill');
      }
      return IssuedBillModel.fromJson(Map<String, dynamic>.from(bill));
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

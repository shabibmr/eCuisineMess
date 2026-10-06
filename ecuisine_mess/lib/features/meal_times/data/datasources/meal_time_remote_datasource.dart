import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/meal_times/data/models/meal_time_model.dart';

abstract interface class MealTimeRemoteDataSource {
  Future<List<MealTimeModel>> getMealTimes({String? cuisineId});

  Future<void> updateMealTime({
    required String id,
    String? name,
    String? startTime,
    String? endTime,
    bool? isActive,
  });
}

class MealTimeRemoteDataSourceImpl implements MealTimeRemoteDataSource {
  MealTimeRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<MealTimeModel>> getMealTimes({String? cuisineId}) async {
    try {
      final query = <String, dynamic>{};
      if (cuisineId != null && cuisineId.isNotEmpty) {
        query['cuisine_id'] = cuisineId;
      }
      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.mealTimes,
        queryParameters: query.isEmpty ? null : query,
      );
      return (res.data ?? [])
          .map(
            (e) => MealTimeModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<void> updateMealTime({
    required String id,
    String? name,
    String? startTime,
    String? endTime,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (startTime != null) body['start_time'] = startTime;
      if (endTime != null) body['end_time'] = endTime;
      if (isActive != null) body['is_active'] = isActive ? 1 : 0;
      await _client.dio.put<void>(ApiEndpoints.mealTime(id), data: body);
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

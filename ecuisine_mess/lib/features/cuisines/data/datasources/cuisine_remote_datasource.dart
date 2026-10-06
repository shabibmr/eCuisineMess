import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/cuisines/data/models/cuisine_model.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_delete_result.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping_input.dart';

abstract interface class CuisineRemoteDataSource {
  Future<List<CuisineModel>> getCuisines({bool includeInactive = false});

  Future<CuisineModel> getCuisine(String id);

  Future<String> createCuisine({
    required String name,
    String? description,
    bool isActive = true,
    List<CuisineItemMappingInput> items = const [],
  });

  Future<void> updateCuisine({
    required String id,
    String? name,
    String? description,
    bool? isActive,
    List<CuisineItemMappingInput>? items,
  });

  Future<int> copyMapping({
    required String targetCuisineId,
    required String sourceCuisineId,
  });

  Future<CuisineDeleteResult> deleteCuisine(String id);
}

class CuisineRemoteDataSourceImpl implements CuisineRemoteDataSource {
  CuisineRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<CuisineModel>> getCuisines({bool includeInactive = false}) async {
    try {
      final query = <String, dynamic>{};
      if (includeInactive) query['include_inactive'] = '1';

      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.cuisines,
        queryParameters: query.isEmpty ? null : query,
      );
      return (res.data ?? [])
          .map(
            (e) => CuisineModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<CuisineModel> getCuisine(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.cuisine(id),
      );
      final data = res.data ?? <String, dynamic>{};
      return CuisineModel.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<String> createCuisine({
    required String name,
    String? description,
    bool isActive = true,
    List<CuisineItemMappingInput> items = const [],
  }) async {
    try {
      final body = <String, dynamic>{
        'cuisine_name': name,
        'is_active': isActive ? 1 : 0,
        if (description != null && description.isNotEmpty)
          'description': description,
        'items': items.map((e) => e.toJson()).toList(),
      };

      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.cuisines,
        data: body,
      );
      return res.data?['id']?.toString() ?? '';
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<void> updateCuisine({
    required String id,
    String? name,
    String? description,
    bool? isActive,
    List<CuisineItemMappingInput>? items,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['cuisine_name'] = name;
      if (description != null) body['description'] = description;
      if (isActive != null) body['is_active'] = isActive ? 1 : 0;
      if (items != null) {
        body['items'] = items.map((e) => e.toJson()).toList();
      }

      await _client.dio.put<void>(
        ApiEndpoints.cuisine(id),
        data: body,
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<int> copyMapping({
    required String targetCuisineId,
    required String sourceCuisineId,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.cuisineCopyMapping(targetCuisineId),
        data: {'source_cuisine_id': sourceCuisineId},
      );
      final data = res.data ?? <String, dynamic>{};
      return (data['copied_count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<CuisineDeleteResult> deleteCuisine(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        ApiEndpoints.cuisine(id),
      );
      final data = res.data ?? const <String, dynamic>{};
      return CuisineDeleteResult(
        action: data['action']?.toString() ?? 'deleted',
        message: data['message']?.toString() ?? 'Cuisine deleted',
      );
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

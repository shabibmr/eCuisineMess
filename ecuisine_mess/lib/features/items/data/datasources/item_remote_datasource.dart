import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/items/data/models/item_model.dart';
import 'package:ecuisine_mess/features/items/data/models/uom_model.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item_delete_result.dart';

abstract interface class ItemRemoteDataSource {
  Future<List<ItemModel>> getItems({
    bool includeInactive = false,
    String? categoryId,
  });

  Future<List<UomModel>> getUoms({bool includeInactive = false});

  Future<String> createItem({
    required String name,
    required String categoryId,
    required String uomId,
    bool isActive = true,
  });

  Future<void> updateItem({
    required String id,
    String? name,
    String? categoryId,
    String? uomId,
    bool? isActive,
  });

  Future<ItemDeleteResult> deleteItem(String id);
}

class ItemRemoteDataSourceImpl implements ItemRemoteDataSource {
  ItemRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<ItemModel>> getItems({
    bool includeInactive = false,
    String? categoryId,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (includeInactive) query['include_inactive'] = '1';
      if (categoryId != null && categoryId.isNotEmpty) {
        query['category_id'] = categoryId;
      }
      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.items,
        queryParameters: query.isEmpty ? null : query,
      );
      return (res.data ?? [])
          .map(
            (e) => ItemModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<List<UomModel>> getUoms({bool includeInactive = false}) async {
    try {
      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.uoms,
        queryParameters:
            includeInactive ? {'include_inactive': '1'} : null,
      );
      return (res.data ?? [])
          .map(
            (e) => UomModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<String> createItem({
    required String name,
    required String categoryId,
    required String uomId,
    bool isActive = true,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.items,
        data: {
          'item_name': name,
          'category_id': categoryId,
          'uom_id': uomId,
          'is_active': isActive ? 1 : 0,
        },
      );
      return res.data?['id']?.toString() ?? '';
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<void> updateItem({
    required String id,
    String? name,
    String? categoryId,
    String? uomId,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['item_name'] = name;
      if (categoryId != null) body['category_id'] = categoryId;
      if (uomId != null) body['uom_id'] = uomId;
      if (isActive != null) body['is_active'] = isActive ? 1 : 0;
      await _client.dio.put<void>(ApiEndpoints.item(id), data: body);
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<ItemDeleteResult> deleteItem(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        ApiEndpoints.item(id),
      );
      final data = res.data ?? const <String, dynamic>{};
      return ItemDeleteResult(
        action: data['action']?.toString() ?? 'deleted',
        message: data['message']?.toString() ?? 'Item deleted',
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

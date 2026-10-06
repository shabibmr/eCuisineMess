import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/item_categories/data/models/item_category_model.dart';

abstract interface class ItemCategoryRemoteDataSource {
  Future<List<ItemCategoryModel>> getCategories({bool includeInactive = false});

  Future<String> createCategory({
    required String name,
    int sortOrder = 0,
    bool isActive = true,
  });

  Future<void> updateCategory({
    required String id,
    String? name,
    int? sortOrder,
    bool? isActive,
  });
}

class ItemCategoryRemoteDataSourceImpl
    implements ItemCategoryRemoteDataSource {
  ItemCategoryRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<ItemCategoryModel>> getCategories({
    bool includeInactive = false,
  }) async {
    try {
      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.itemCategories,
        queryParameters:
            includeInactive ? {'include_inactive': '1'} : null,
      );
      return (res.data ?? [])
          .map(
            (e) => ItemCategoryModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<String> createCategory({
    required String name,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.itemCategories,
        data: {
          'category_name': name,
          'sort_order': sortOrder,
          'is_active': isActive ? 1 : 0,
        },
      );
      return res.data?['id']?.toString() ?? '';
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<void> updateCategory({
    required String id,
    String? name,
    int? sortOrder,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['category_name'] = name;
      if (sortOrder != null) body['sort_order'] = sortOrder;
      if (isActive != null) body['is_active'] = isActive ? 1 : 0;
      await _client.dio.put<void>(ApiEndpoints.itemCategory(id), data: body);
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

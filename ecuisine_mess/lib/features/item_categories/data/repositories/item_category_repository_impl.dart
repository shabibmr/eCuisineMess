import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/item_categories/data/datasources/item_category_remote_datasource.dart';
import 'package:ecuisine_mess/features/item_categories/domain/entities/item_category.dart';
import 'package:ecuisine_mess/features/item_categories/domain/repositories/item_category_repository.dart';

class ItemCategoryRepositoryImpl implements ItemCategoryRepository {
  ItemCategoryRepositoryImpl(this._remote);

  final ItemCategoryRemoteDataSource _remote;

  @override
  Future<List<ItemCategory>> getCategories({
    bool includeInactive = false,
  }) async {
    try {
      final list =
          await _remote.getCategories(includeInactive: includeInactive);
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<String> createCategory({
    required String name,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    try {
      return await _remote.createCategory(
        name: name,
        sortOrder: sortOrder,
        isActive: isActive,
      );
    } on Object catch (e) {
      throw mapException(e);
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
      await _remote.updateCategory(
        id: id,
        name: name,
        sortOrder: sortOrder,
        isActive: isActive,
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}

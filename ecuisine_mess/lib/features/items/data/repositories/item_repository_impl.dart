import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/items/data/datasources/item_remote_datasource.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item_delete_result.dart';
import 'package:ecuisine_mess/features/items/domain/entities/uom.dart';
import 'package:ecuisine_mess/features/items/domain/repositories/item_repository.dart';

class ItemRepositoryImpl implements ItemRepository {
  ItemRepositoryImpl(this._remote);

  final ItemRemoteDataSource _remote;

  @override
  Future<List<Item>> getItems({
    bool includeInactive = false,
    String? categoryId,
  }) async {
    try {
      final list = await _remote.getItems(
        includeInactive: includeInactive,
        categoryId: categoryId,
      );
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<Uom>> getUoms({bool includeInactive = false}) async {
    try {
      final list = await _remote.getUoms(includeInactive: includeInactive);
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
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
      return await _remote.createItem(
        name: name,
        categoryId: categoryId,
        uomId: uomId,
        isActive: isActive,
      );
    } on Object catch (e) {
      throw mapException(e);
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
      await _remote.updateItem(
        id: id,
        name: name,
        categoryId: categoryId,
        uomId: uomId,
        isActive: isActive,
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<ItemDeleteResult> deleteItem(String id) async {
    try {
      return await _remote.deleteItem(id);
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}

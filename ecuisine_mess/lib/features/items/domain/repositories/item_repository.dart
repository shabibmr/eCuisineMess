import 'package:ecuisine_mess/features/items/domain/entities/item.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item_delete_result.dart';
import 'package:ecuisine_mess/features/items/domain/entities/uom.dart';

abstract interface class ItemRepository {
  Future<List<Item>> getItems({
    bool includeInactive = false,
    String? categoryId,
  });

  Future<List<Uom>> getUoms({bool includeInactive = false});

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

import 'package:ecuisine_mess/features/item_categories/domain/entities/item_category.dart';

abstract interface class ItemCategoryRepository {
  Future<List<ItemCategory>> getCategories({bool includeInactive = false});

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

import 'package:ecuisine_mess/features/item_categories/domain/entities/item_category.dart';

class ItemCategoryModel {
  const ItemCategoryModel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  factory ItemCategoryModel.fromJson(Map<String, dynamic> json) {
    return ItemCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['category_name']?.toString() ?? '',
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'category_name': name,
        'sort_order': sortOrder,
        'is_active': isActive ? 1 : 0,
      };

  Map<String, dynamic> toUpdateJson({
    String? name,
    int? sortOrder,
    bool? isActive,
  }) {
    final body = <String, dynamic>{};
    if (name != null) body['category_name'] = name;
    if (sortOrder != null) body['sort_order'] = sortOrder;
    if (isActive != null) body['is_active'] = isActive ? 1 : 0;
    return body;
  }

  ItemCategory toEntity() => ItemCategory(
        id: id,
        name: name,
        sortOrder: sortOrder,
        isActive: isActive,
      );
}

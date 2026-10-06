import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping.dart';

class CuisineItemMappingModel {
  const CuisineItemMappingModel({
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.defaultQty,
    required this.sortOrder,
    this.categoryId,
    this.category,
    this.uomId,
  });

  final String itemId;
  final String itemName;
  final String unit;
  final double defaultQty;
  final int sortOrder;
  final String? categoryId;
  final String? category;
  final String? uomId;

  factory CuisineItemMappingModel.fromJson(Map<String, dynamic> json) {
    return CuisineItemMappingModel(
      itemId: (json['item_id'] ?? json['id'] ?? '').toString(),
      itemName: (json['item_name'] ?? json['name'] ?? '').toString(),
      unit: (json['unit'] ?? json['uom_name'] ?? 'Nos').toString(),
      defaultQty: (json['default_qty'] as num?)?.toDouble() ?? 1.0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      categoryId: json['category_id']?.toString(),
      category: json['category']?.toString(),
      uomId: json['uom_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'item_name': itemName,
        'unit': unit,
        'default_qty': defaultQty,
        'sort_order': sortOrder,
        if (categoryId != null) 'category_id': categoryId,
        if (category != null) 'category': category,
        if (uomId != null) 'uom_id': uomId,
      };

  CuisineItemMapping toEntity() => CuisineItemMapping(
        itemId: itemId,
        itemName: itemName,
        unit: unit,
        defaultQty: defaultQty,
        sortOrder: sortOrder,
        categoryId: categoryId,
        category: category,
        uomId: uomId,
      );

  factory CuisineItemMappingModel.fromEntity(CuisineItemMapping entity) =>
      CuisineItemMappingModel(
        itemId: entity.itemId,
        itemName: entity.itemName,
        unit: entity.unit,
        defaultQty: entity.defaultQty,
        sortOrder: entity.sortOrder,
        categoryId: entity.categoryId,
        category: entity.category,
        uomId: entity.uomId,
      );
}

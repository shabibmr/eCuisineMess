import 'package:ecuisine_mess/features/items/domain/entities/item.dart';

class ItemModel {
  const ItemModel({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName = '',
    this.uomId,
    this.uomName = 'Nos',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? categoryId;
  final String categoryName;
  final String? uomId;
  final String uomName;
  final bool isActive;

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['item_id'];
    return ItemModel(
      id: rawId?.toString() ?? '',
      name: json['item_name']?.toString() ?? json['name']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString() ??
          json['category']?.toString() ??
          '',
      uomId: json['uom_id']?.toString(),
      uomName: json['uom_name']?.toString() ??
          json['unit']?.toString() ??
          'Nos',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Item toEntity() => Item(
        id: id,
        name: name,
        categoryId: categoryId,
        categoryName: categoryName,
        uomId: uomId,
        uomName: uomName,
        isActive: isActive,
      );
}

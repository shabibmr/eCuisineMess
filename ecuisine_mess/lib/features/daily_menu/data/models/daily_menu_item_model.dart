import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item.dart';

class DailyMenuItemModel {
  const DailyMenuItemModel({
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    this.notes,
    this.categoryId,
    this.category,
    this.uomId,
  });

  final String itemId;
  final String itemName;
  final String unit;
  final double quantity;
  final String? notes;
  final String? categoryId;
  final String? category;
  final String? uomId;

  /// GET /menus items[] use `id` (item PK); some payloads may send `item_id`.
  factory DailyMenuItemModel.fromJson(Map<String, dynamic> json) {
    return DailyMenuItemModel(
      itemId: (json['item_id'] ?? json['id'] ?? '').toString(),
      itemName: (json['item_name'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      quantity: _asDouble(json['quantity']),
      notes: json['notes']?.toString(),
      categoryId: json['category_id']?.toString(),
      category: json['category']?.toString(),
      uomId: json['uom_id']?.toString(),
    );
  }

  DailyMenuItem toEntity() => DailyMenuItem(
        itemId: itemId,
        itemName: itemName,
        unit: unit,
        quantity: quantity,
        notes: notes,
        categoryId: categoryId,
        category: category,
        uomId: uomId,
      );

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

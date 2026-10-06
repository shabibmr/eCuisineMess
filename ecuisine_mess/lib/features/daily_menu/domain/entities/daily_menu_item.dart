import 'package:equatable/equatable.dart';

/// One line on a daily menu slot (GET /menus items[]).
class DailyMenuItem extends Equatable {
  const DailyMenuItem({
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

  DailyMenuItem copyWith({
    String? itemId,
    String? itemName,
    String? unit,
    double? quantity,
    String? notes,
    String? categoryId,
    String? category,
    String? uomId,
  }) {
    return DailyMenuItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      uomId: uomId ?? this.uomId,
    );
  }

  @override
  List<Object?> get props => [
        itemId,
        itemName,
        unit,
        quantity,
        notes,
        categoryId,
        category,
        uomId,
      ];
}

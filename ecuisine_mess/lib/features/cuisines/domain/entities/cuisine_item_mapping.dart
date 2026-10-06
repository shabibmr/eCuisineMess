import 'package:equatable/equatable.dart';

class CuisineItemMapping extends Equatable {
  const CuisineItemMapping({
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

  CuisineItemMapping copyWith({
    String? itemId,
    String? itemName,
    String? unit,
    double? defaultQty,
    int? sortOrder,
    String? categoryId,
    String? category,
    String? uomId,
  }) {
    return CuisineItemMapping(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      unit: unit ?? this.unit,
      defaultQty: defaultQty ?? this.defaultQty,
      sortOrder: sortOrder ?? this.sortOrder,
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
        defaultQty,
        sortOrder,
        categoryId,
        category,
        uomId,
      ];
}

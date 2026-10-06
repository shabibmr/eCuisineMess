import 'package:equatable/equatable.dart';

class CuisineItemMappingInput extends Equatable {
  const CuisineItemMappingInput({
    required this.itemId,
    this.defaultQty = 1.0,
    this.sortOrder = 0,
  });

  final String itemId;
  final double defaultQty;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'default_qty': defaultQty,
        'sort_order': sortOrder,
      };

  @override
  List<Object?> get props => [itemId, defaultQty, sortOrder];
}

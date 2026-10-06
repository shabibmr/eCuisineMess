import 'package:ecuisine_mess/features/items/data/models/item_model.dart';
import 'package:ecuisine_mess/features/items/data/models/uom_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ItemModel maps API JSON fields', () {
    final model = ItemModel.fromJson({
      'id': 'i1',
      'item_name': 'Rice',
      'category_id': 'c1',
      'category_name': 'Staple',
      'uom_id': 'u1',
      'uom_name': 'Kg',
      'is_active': 1,
    });

    final item = model.toEntity();
    expect(item.id, 'i1');
    expect(item.name, 'Rice');
    expect(item.categoryId, 'c1');
    expect(item.categoryName, 'Staple');
    expect(item.uomId, 'u1');
    expect(item.uomName, 'Kg');
    expect(item.isActive, isTrue);
  });

  test('UomModel maps seed UOM JSON', () {
    final model = UomModel.fromJson({
      'id': 'u1',
      'uom_name': 'Nos',
      'sort_order': 1,
      'is_active': true,
    });
    final uom = model.toEntity();
    expect(uom.name, 'Nos');
    expect(uom.sortOrder, 1);
    expect(uom.isActive, isTrue);
  });
}

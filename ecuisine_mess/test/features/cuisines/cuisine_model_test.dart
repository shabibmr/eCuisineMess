import 'package:ecuisine_mess/features/cuisines/data/models/cuisine_item_mapping_model.dart';
import 'package:ecuisine_mess/features/cuisines/data/models/cuisine_model.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_delete_result.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CuisineModel & CuisineItemMappingModel Tests', () {
    test('CuisineItemMappingModel parses JSON and maps to domain entity', () {
      final json = {
        'id': 'itm-123',
        'item_name': 'Paneer Butter Masala',
        'unit': 'Plate',
        'default_qty': 2.5,
        'sort_order': 1,
        'category_id': 'cat-1',
        'category': 'Main Course',
        'uom_id': 'uom-1',
      };

      final model = CuisineItemMappingModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity.itemId, 'itm-123');
      expect(entity.itemName, 'Paneer Butter Masala');
      expect(entity.unit, 'Plate');
      expect(entity.defaultQty, 2.5);
      expect(entity.sortOrder, 1);
      expect(entity.category, 'Main Course');
    });

    test('CuisineModel parses cuisine with mapped items and aggregate counts', () {
      final json = {
        'id': 'c-100',
        'cuisine_name': 'North Indian',
        'description': 'Delicious traditional curries and rotis',
        'is_active': 1,
        'mapped_items_count': 2,
        'active_members_count': 15,
        'items': [
          {
            'item_id': 'itm-1',
            'item_name': 'Dal Tadka',
            'unit': 'Bowl',
            'default_qty': 1.0,
            'sort_order': 0,
          },
          {
            'item_id': 'itm-2',
            'item_name': 'Roti',
            'unit': 'Nos',
            'default_qty': 4.0,
            'sort_order': 1,
          },
        ],
      };

      final model = CuisineModel.fromJson(json);
      final entity = model.toEntity();

      expect(entity.id, 'c-100');
      expect(entity.cuisineName, 'North Indian');
      expect(entity.description, 'Delicious traditional curries and rotis');
      expect(entity.isActive, isTrue);
      expect(entity.mappedItemsCount, 2);
      expect(entity.activeMembersCount, 15);
      expect(entity.items.length, 2);
      expect(entity.items[0].itemName, 'Dal Tadka');
      expect(entity.items[1].defaultQty, 4.0);
    });

    test('CuisineItemMappingInput converts correctly to JSON payload', () {
      const input = CuisineItemMappingInput(
        itemId: 'itm-99',
        defaultQty: 3.0,
        sortOrder: 2,
      );

      final json = input.toJson();
      expect(json['item_id'], 'itm-99');
      expect(json['default_qty'], 3.0);
      expect(json['sort_order'], 2);
    });

    test('CuisineDeleteResult identifies deactivation vs deletion', () {
      const deact = CuisineDeleteResult(
        action: 'deactivated',
        message: 'Marked as inactive',
      );
      expect(deact.wasDeactivated, isTrue);

      const del = CuisineDeleteResult(
        action: 'deleted',
        message: 'Deleted successfully',
      );
      expect(del.wasDeactivated, isFalse);
    });
  });
}

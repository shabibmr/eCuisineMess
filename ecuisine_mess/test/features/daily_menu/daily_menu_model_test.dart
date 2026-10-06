import 'package:ecuisine_mess/features/daily_menu/data/models/copy_meal_result_model.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/copy_menus_result_model.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/daily_menu_model.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/menu_day_status_model.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/save_day_result_model.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/cuisine_menu_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyMenu models', () {
    test('DailyMenuModel parses slot with items (item id as id)', () {
      final model = DailyMenuModel.fromJson({
        'id': 'menu-1',
        'menu_date': '2026-10-06',
        'cuisine_id': 'c-1',
        'cuisine_name': 'North Indian',
        'meal_type': 'LUNCH',
        'notes': 'spicy',
        'is_locked': 1,
        'items': [
          {
            'id': 'itm-1',
            'item_name': 'Dal',
            'unit': 'Bowl',
            'quantity': 1.5,
            'notes': null,
            'category_id': 'cat-1',
            'category': 'Main',
            'uom_id': 'uom-1',
          },
        ],
      });
      final entity = model.toEntity();

      expect(entity.id, 'menu-1');
      expect(entity.menuDate, '2026-10-06');
      expect(entity.cuisineName, 'North Indian');
      expect(entity.mealType, 'LUNCH');
      expect(entity.isLocked, isTrue);
      expect(entity.items, hasLength(1));
      expect(entity.items.first.itemId, 'itm-1');
      expect(entity.items.first.itemName, 'Dal');
      expect(entity.items.first.quantity, 1.5);
      expect(entity.items.first.category, 'Main');
    });

    test('MenuDayStatusModel parses FULL/PARTIAL readiness', () {
      final model = MenuDayStatusModel.fromJson({
        'menu_date': '2026-10-06T00:00:00',
        'readiness': [
          {
            'cuisine_id': 'c-1',
            'cuisine_name': 'South',
            'status': 'PARTIAL',
            'filled_count': 2,
            'total_slots': 3,
            'BREAKFAST': true,
            'LUNCH': true,
            'DINNER': false,
          },
          {
            'cuisine_id': 'c-2',
            'cuisine_name': 'North',
            'status': 'FULL',
            'filled_count': 3,
            'total_slots': 3,
            'slots': {
              'BREAKFAST': true,
              'LUNCH': true,
              'DINNER': true,
            },
          },
        ],
      });
      final entity = model.toEntity();

      expect(entity.menuDate, '2026-10-06');
      expect(entity.readiness, hasLength(2));
      expect(entity.readiness[0].status, MenuFillStatus.partial);
      expect(entity.readiness[0].dinner, isFalse);
      expect(entity.readiness[1].status, MenuFillStatus.full);
      expect(entity.readiness[1].breakfast, isTrue);
    });

    test('SaveDayResultModel and copy result models parse API payloads', () {
      final save = SaveDayResultModel.fromJson({
        'success': true,
        'menu_date': '2026-10-06',
        'saved_slots_count': 3,
        'message': 'ok',
      }).toEntity();
      expect(save.savedSlotsCount, 3);
      expect(save.success, isTrue);

      final copy = CopyMenusResultModel.fromJson({
        'success': true,
        'copied': 2,
        'copied_slots_count': 2,
        'skipped': [
          {
            'cuisine_id': 'c-1',
            'cuisine_name': 'South',
            'meal_type': 'DINNER',
            'item_id': null,
            'item_name': null,
            'reason': 'Target slot already exists and overwrite is False',
          },
        ],
        'message': 'Copied 2',
      }).toEntity();
      expect(copy.copiedSlotsCount, 2);
      expect(copy.skipped, hasLength(1));
      expect(copy.skipped.first.mealType, 'DINNER');

      final meal = CopyMealResultModel.fromJson({
        'success': true,
        'copied_cuisines': ['North'],
        'skipped': [
          {
            'to_cuisine_id': 'c-9',
            'to_cuisine_name': 'East',
            'reason': 'Target slot is locked (bills exist)',
          },
        ],
        'message': 'Meal LUNCH copied to 1 cuisines.',
      }).toEntity();
      expect(meal.copiedCuisines, ['North']);
      expect(meal.skipped.first.itemId, isNull);
      expect(meal.skipped.first.reason, contains('locked'));
    });
  });
}

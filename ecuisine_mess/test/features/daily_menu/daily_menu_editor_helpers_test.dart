import 'package:ecuisine_mess/features/daily_menu/domain/entities/cuisine_menu_status.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/daily_menu_editor_bloc.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyMenuEditorBloc helpers', () {
    test('formatDate pads year month day', () {
      expect(
        DailyMenuEditorBloc.formatDate(DateTime(2026, 3, 5)),
        '2026-03-05',
      );
    });

    test('shiftDate moves calendar day', () {
      expect(DailyMenuEditorBloc.shiftDate('2026-03-01', -1), '2026-02-28');
      expect(DailyMenuEditorBloc.shiftDate('2026-03-01', 1), '2026-03-02');
    });

    test('isPastDate compares against today', () {
      final now = DateTime(2026, 10, 6);
      expect(
        DailyMenuEditorBloc.isPastDate('2026-10-05', now: now),
        isTrue,
      );
      expect(
        DailyMenuEditorBloc.isPastDate('2026-10-06', now: now),
        isFalse,
      );
      expect(
        DailyMenuEditorBloc.isPastDate('2026-10-07', now: now),
        isFalse,
      );
    });

    test('buildSlots fills empty cuisine × meal grid from menus', () {
      const cuisines = [
        CuisineOption(id: 'c1', name: 'Indian'),
        CuisineOption(id: 'c2', name: 'Arabic'),
      ];
      const menus = [
        DailyMenu(
          id: 'm1',
          menuDate: '2026-10-06',
          cuisineId: 'c1',
          mealType: 'LUNCH',
          isLocked: true,
          items: [
            DailyMenuItem(
              itemId: 'i1',
              itemName: 'Rice',
              unit: 'Plate',
              quantity: 1,
            ),
          ],
        ),
      ];

      final slots = DailyMenuEditorBloc.buildSlots(cuisines, menus);
      expect(slots, hasLength(6));

      final lunch = slots.firstWhere(
        (s) => s.cuisineId == 'c1' && s.mealType == 'LUNCH',
      );
      expect(lunch.menuId, 'm1');
      expect(lunch.isLocked, isTrue);
      expect(lunch.items, hasLength(1));
      expect(lunch.items.first.itemName, 'Rice');

      final empty = slots.firstWhere(
        (s) => s.cuisineId == 'c2' && s.mealType == 'BREAKFAST',
      );
      expect(empty.menuId, isNull);
      expect(empty.items, isEmpty);
    });

    test('deriveReadiness maps empty/partial/full', () {
      const cuisines = [
        CuisineOption(id: 'c1', name: 'Indian'),
        CuisineOption(id: 'c2', name: 'Arabic'),
      ];
      final slots = [
        const MenuSlotEdit(
          cuisineId: 'c1',
          mealType: 'BREAKFAST',
          items: [
            MenuSlotLine(
              itemId: 'i1',
              itemName: 'Idli',
              unit: 'Nos',
              quantity: 1,
            ),
          ],
        ),
        const MenuSlotEdit(cuisineId: 'c1', mealType: 'LUNCH'),
        const MenuSlotEdit(cuisineId: 'c1', mealType: 'DINNER'),
        const MenuSlotEdit(cuisineId: 'c2', mealType: 'BREAKFAST'),
        const MenuSlotEdit(cuisineId: 'c2', mealType: 'LUNCH'),
        const MenuSlotEdit(cuisineId: 'c2', mealType: 'DINNER'),
      ];

      final readiness = DailyMenuEditorBloc.deriveReadiness(cuisines, slots);
      expect(readiness, hasLength(2));
      expect(readiness[0].status, MenuFillStatus.partial);
      expect(readiness[0].filledCount, 1);
      expect(readiness[0].breakfast, isTrue);
      expect(readiness[1].status, MenuFillStatus.empty);
      expect(readiness[1].filledCount, 0);
    });
  });
}

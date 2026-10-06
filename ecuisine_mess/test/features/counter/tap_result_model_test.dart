import 'package:ecuisine_mess/features/counter/data/models/tap_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TapResultModel parses success with today strip and items', () {
    final model = TapResultModel.fromJson({
      'success': true,
      'meal_type': 'LUNCH',
      'total_amount': 0,
      'member': {
        'id': 'm1',
        'name': 'Rahul',
        'phone': '971',
        'cuisine_id': 'c1',
        'cuisine_name': 'South Indian',
        'days_left': 10,
        'status': 'ACTIVE',
      },
      'today': {
        'BREAKFAST': true,
        'LUNCH': false,
        'DINNER': false,
      },
      'items': [
        {
          'item_id': 'i1',
          'item_name': 'Rice',
          'quantity': 1,
          'unit': 'Nos',
          'category_name': 'Main',
        },
      ],
    });

    final entity = model.toEntity();
    expect(entity.success, isTrue);
    expect(entity.member?.name, 'Rahul');
    expect(entity.member?.cuisineId, 'c1');
    expect(entity.today.breakfast, isTrue);
    expect(entity.today.lunch, isFalse);
    expect(entity.items.single.name, 'Rice');
    expect(entity.canOverride, isFalse);
  });

  test('ALREADY_SERVED allows override', () {
    final model = TapResultModel.fromJson({
      'success': false,
      'error_code': 'ALREADY_SERVED',
      'message': 'Already served',
      'member': {'id': 'm1', 'name': 'Rahul'},
      'meal_type': 'LUNCH',
    });
    expect(model.toEntity().canOverride, isTrue);
  });
}

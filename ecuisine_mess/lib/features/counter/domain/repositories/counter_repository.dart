import 'package:ecuisine_mess/features/counter/domain/entities/counter_tap_result.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/issued_bill.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';

abstract interface class CounterRepository {
  Future<MealWindow?> getCurrentMealWindow({String? cuisineId});

  Future<CounterTapResult> tapRfid(String rfidTag);

  Future<IssuedBill> issueToken({
    required String memberId,
    required String mealType,
    bool isOverride = false,
    String? overrideBy,
    String? overrideReason,
  });
}

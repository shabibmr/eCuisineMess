import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/counter/data/datasources/counter_remote_datasource.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/counter_tap_result.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/issued_bill.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';
import 'package:ecuisine_mess/features/counter/domain/repositories/counter_repository.dart';

class CounterRepositoryImpl implements CounterRepository {
  CounterRepositoryImpl(this._remote);

  final CounterRemoteDataSource _remote;

  @override
  Future<MealWindow?> getCurrentMealWindow({String? cuisineId}) async {
    try {
      final model =
          await _remote.getCurrentMealWindow(cuisineId: cuisineId);
      return model?.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<CounterTapResult> tapRfid(String rfidTag) async {
    try {
      final model = await _remote.tapRfid(rfidTag);
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<IssuedBill> issueToken({
    required String memberId,
    required String mealType,
    bool isOverride = false,
    String? overrideBy,
    String? overrideReason,
  }) async {
    try {
      final model = await _remote.issueToken(
        memberId: memberId,
        mealType: mealType,
        isOverride: isOverride,
        overrideBy: overrideBy,
        overrideReason: overrideReason,
      );
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}

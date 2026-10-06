import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/daily_menu/data/datasources/daily_menu_remote_datasource.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/copy_meal_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/copy_menus_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/cuisine_menu_status.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/day_menu_slot_input.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/menu_history_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/save_day_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/repositories/daily_menu_repository.dart';

class DailyMenuRepositoryImpl implements DailyMenuRepository {
  DailyMenuRepositoryImpl(this._remote);

  final DailyMenuRemoteDataSource _remote;

  @override
  Future<List<DailyMenu>> getMenus({
    String? menuDate,
    String? cuisineId,
    String? mealType,
  }) async {
    try {
      final list = await _remote.getMenus(
        menuDate: menuDate,
        cuisineId: cuisineId,
        mealType: mealType,
      );
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<MenuDayStatus> getMenuStatus({String? menuDate}) async {
    try {
      final model = await _remote.getMenuStatus(menuDate: menuDate);
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<SaveDayResult> saveDay({
    required String menuDate,
    required List<DayMenuSlotInput> menus,
  }) async {
    try {
      final model = await _remote.saveDay(menuDate: menuDate, menus: menus);
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<CopyMenusResult> copyMenus({
    required String fromDate,
    required String toDate,
    bool overwrite = false,
  }) async {
    try {
      final model = await _remote.copyMenus(
        fromDate: fromDate,
        toDate: toDate,
        overwrite: overwrite,
      );
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<CopyMealResult> copyMeal({
    required String menuDate,
    required String fromCuisineId,
    required String mealType,
    required List<String> toCuisineIds,
  }) async {
    try {
      final model = await _remote.copyMeal(
        menuDate: menuDate,
        fromCuisineId: fromCuisineId,
        mealType: mealType,
        toCuisineIds: toCuisineIds,
      );
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<MenuHistoryResult> getMenuHistory({
    String? fromDate,
    String? toDate,
    String? cuisineId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final model = await _remote.getMenuHistory(
        fromDate: fromDate,
        toDate: toDate,
        cuisineId: cuisineId,
        limit: limit,
        offset: offset,
      );
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}

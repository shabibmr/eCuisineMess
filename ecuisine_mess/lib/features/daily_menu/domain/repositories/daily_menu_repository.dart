import 'package:ecuisine_mess/features/daily_menu/domain/entities/copy_meal_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/copy_menus_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/cuisine_menu_status.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/day_menu_slot_input.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/menu_history_result.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/save_day_result.dart';

abstract class DailyMenuRepository {
  Future<List<DailyMenu>> getMenus({
    String? menuDate,
    String? cuisineId,
    String? mealType,
  });

  Future<MenuDayStatus> getMenuStatus({String? menuDate});

  Future<SaveDayResult> saveDay({
    required String menuDate,
    required List<DayMenuSlotInput> menus,
  });

  Future<CopyMenusResult> copyMenus({
    required String fromDate,
    required String toDate,
    bool overwrite = false,
  });

  Future<CopyMealResult> copyMeal({
    required String menuDate,
    required String fromCuisineId,
    required String mealType,
    required List<String> toCuisineIds,
  });

  Future<MenuHistoryResult> getMenuHistory({
    String? fromDate,
    String? toDate,
    String? cuisineId,
    int limit = 50,
    int offset = 0,
  });
}

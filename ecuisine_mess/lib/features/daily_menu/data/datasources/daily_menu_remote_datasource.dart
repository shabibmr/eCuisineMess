import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/error/exceptions.dart';
import 'package:ecuisine_mess/core/network/api_client.dart';
import 'package:ecuisine_mess/core/network/api_endpoints.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/copy_meal_result_model.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/copy_menus_result_model.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/daily_menu_model.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/menu_day_status_model.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/menu_history_result_model.dart';
import 'package:ecuisine_mess/features/daily_menu/data/models/save_day_result_model.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item_input.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/day_menu_slot_input.dart';

abstract interface class DailyMenuRemoteDataSource {
  Future<List<DailyMenuModel>> getMenus({
    String? menuDate,
    String? cuisineId,
    String? mealType,
  });

  Future<MenuDayStatusModel> getMenuStatus({String? menuDate});

  Future<SaveDayResultModel> saveDay({
    required String menuDate,
    required List<DayMenuSlotInput> menus,
  });

  Future<CopyMenusResultModel> copyMenus({
    required String fromDate,
    required String toDate,
    bool overwrite = false,
  });

  Future<CopyMealResultModel> copyMeal({
    required String menuDate,
    required String fromCuisineId,
    required String mealType,
    required List<String> toCuisineIds,
  });

  Future<MenuHistoryResultModel> getMenuHistory({
    String? fromDate,
    String? toDate,
    String? cuisineId,
    int limit = 50,
    int offset = 0,
  });
}

class DailyMenuRemoteDataSourceImpl implements DailyMenuRemoteDataSource {
  DailyMenuRemoteDataSourceImpl(this._client);

  final ApiClient _client;

  @override
  Future<List<DailyMenuModel>> getMenus({
    String? menuDate,
    String? cuisineId,
    String? mealType,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (menuDate != null && menuDate.isNotEmpty) {
        query['menu_date'] = menuDate;
      }
      if (cuisineId != null && cuisineId.isNotEmpty) {
        query['cuisine_id'] = cuisineId;
      }
      if (mealType != null && mealType.isNotEmpty) {
        query['meal_type'] = mealType;
      }

      final res = await _client.dio.get<List<dynamic>>(
        ApiEndpoints.menus,
        queryParameters: query.isEmpty ? null : query,
      );
      return (res.data ?? [])
          .map(
            (e) => DailyMenuModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<MenuDayStatusModel> getMenuStatus({String? menuDate}) async {
    try {
      final query = <String, dynamic>{};
      if (menuDate != null && menuDate.isNotEmpty) {
        query['menu_date'] = menuDate;
      }
      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.menusStatus,
        queryParameters: query.isEmpty ? null : query,
      );
      return MenuDayStatusModel.fromJson(
        Map<String, dynamic>.from(res.data ?? const {}),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<SaveDayResultModel> saveDay({
    required String menuDate,
    required List<DayMenuSlotInput> menus,
  }) async {
    try {
      final body = <String, dynamic>{
        'menu_date': menuDate,
        'menus': menus.map(_slotToJson).toList(),
      };
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.menusSaveDay,
        data: body,
      );
      return SaveDayResultModel.fromJson(
        Map<String, dynamic>.from(res.data ?? const {}),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<CopyMenusResultModel> copyMenus({
    required String fromDate,
    required String toDate,
    bool overwrite = false,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.menusCopy,
        data: <String, dynamic>{
          'from_date': fromDate,
          'to_date': toDate,
          'overwrite': overwrite,
        },
      );
      return CopyMenusResultModel.fromJson(
        Map<String, dynamic>.from(res.data ?? const {}),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<CopyMealResultModel> copyMeal({
    required String menuDate,
    required String fromCuisineId,
    required String mealType,
    required List<String> toCuisineIds,
  }) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        ApiEndpoints.menusCopyMeal,
        data: <String, dynamic>{
          'menu_date': menuDate,
          'from_cuisine_id': fromCuisineId,
          'meal_type': mealType,
          'to_cuisine_ids': toCuisineIds,
        },
      );
      return CopyMealResultModel.fromJson(
        Map<String, dynamic>.from(res.data ?? const {}),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  @override
  Future<MenuHistoryResultModel> getMenuHistory({
    String? fromDate,
    String? toDate,
    String? cuisineId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final query = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (fromDate != null && fromDate.isNotEmpty) {
        query['from_date'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        query['to_date'] = toDate;
      }
      if (cuisineId != null && cuisineId.isNotEmpty) {
        query['cuisine_id'] = cuisineId;
      }

      final res = await _client.dio.get<Map<String, dynamic>>(
        ApiEndpoints.menusHistory,
        queryParameters: query,
      );
      return MenuHistoryResultModel.fromJson(
        Map<String, dynamic>.from(res.data ?? const {}),
      );
    } on DioException catch (e) {
      throw _unwrap(e);
    }
  }

  Map<String, dynamic> _slotToJson(DayMenuSlotInput slot) {
    return <String, dynamic>{
      'cuisine_id': slot.cuisineId,
      'meal_type': slot.mealType,
      'items': slot.items.map(_itemToJson).toList(),
      if (slot.notes != null) 'notes': slot.notes,
      'is_locked': slot.isLocked ? 1 : 0,
    };
  }

  Map<String, dynamic> _itemToJson(DailyMenuItemInput item) {
    return <String, dynamic>{
      'item_id': item.itemId,
      'quantity': item.quantity,
      if (item.notes != null) 'notes': item.notes,
    };
  }

  Object _unwrap(DioException e) {
    final err = e.error;
    if (err is AppException) return err;
    return AppException(e.message ?? 'Request failed');
  }
}

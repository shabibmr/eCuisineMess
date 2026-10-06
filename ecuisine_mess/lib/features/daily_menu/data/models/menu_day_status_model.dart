import 'package:ecuisine_mess/features/daily_menu/domain/entities/cuisine_menu_status.dart';

class CuisineMenuStatusModel {
  const CuisineMenuStatusModel({
    required this.cuisineId,
    required this.cuisineName,
    required this.status,
    required this.filledCount,
    this.totalSlots = 3,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final String cuisineId;
  final String cuisineName;
  final MenuFillStatus status;
  final int filledCount;
  final int totalSlots;
  final bool breakfast;
  final bool lunch;
  final bool dinner;

  factory CuisineMenuStatusModel.fromJson(Map<String, dynamic> json) {
    final slots = json['slots'];
    Map<String, dynamic>? slotsMap;
    if (slots is Map) {
      slotsMap = Map<String, dynamic>.from(slots);
    }

    return CuisineMenuStatusModel(
      cuisineId: (json['cuisine_id'] ?? '').toString(),
      cuisineName: (json['cuisine_name'] ?? '').toString(),
      status: _parseFillStatus(json['status']?.toString()),
      filledCount: (json['filled_count'] as num?)?.toInt() ?? 0,
      totalSlots: (json['total_slots'] as num?)?.toInt() ?? 3,
      breakfast: _asBool(json['BREAKFAST'] ?? slotsMap?['BREAKFAST']),
      lunch: _asBool(json['LUNCH'] ?? slotsMap?['LUNCH']),
      dinner: _asBool(json['DINNER'] ?? slotsMap?['DINNER']),
    );
  }

  CuisineMenuStatus toEntity() => CuisineMenuStatus(
        cuisineId: cuisineId,
        cuisineName: cuisineName,
        status: status,
        filledCount: filledCount,
        totalSlots: totalSlots,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
      );

  static MenuFillStatus _parseFillStatus(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'FULL':
        return MenuFillStatus.full;
      case 'PARTIAL':
        return MenuFillStatus.partial;
      default:
        return MenuFillStatus.empty;
    }
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }
}

class MenuDayStatusModel {
  const MenuDayStatusModel({
    required this.menuDate,
    required this.readiness,
  });

  final String menuDate;
  final List<CuisineMenuStatusModel> readiness;

  factory MenuDayStatusModel.fromJson(Map<String, dynamic> json) {
    final raw = json['readiness'] as List<dynamic>? ?? const [];
    final date = json['menu_date']?.toString() ?? '';
    return MenuDayStatusModel(
      menuDate: date.length >= 10 ? date.substring(0, 10) : date,
      readiness: raw
          .map(
            (e) => CuisineMenuStatusModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  MenuDayStatus toEntity() => MenuDayStatus(
        menuDate: menuDate,
        readiness: readiness.map((e) => e.toEntity()).toList(),
      );
}

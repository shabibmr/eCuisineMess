import 'package:ecuisine_mess/features/daily_menu/data/models/daily_menu_item_model.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';

class DailyMenuModel {
  const DailyMenuModel({
    required this.id,
    required this.menuDate,
    required this.cuisineId,
    this.cuisineName,
    required this.mealType,
    this.notes,
    this.isLocked = false,
    this.items = const [],
  });

  final String id;
  final String menuDate;
  final String cuisineId;
  final String? cuisineName;
  final String mealType;
  final String? notes;
  final bool isLocked;
  final List<DailyMenuItemModel> items;

  factory DailyMenuModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return DailyMenuModel(
      id: (json['id'] ?? '').toString(),
      menuDate: _asDateString(json['menu_date']),
      cuisineId: (json['cuisine_id'] ?? '').toString(),
      cuisineName: json['cuisine_name']?.toString(),
      mealType: (json['meal_type'] ?? '').toString(),
      notes: json['notes']?.toString(),
      isLocked: _asBool(json['is_locked']),
      items: rawItems
          .map(
            (e) => DailyMenuItemModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  DailyMenu toEntity() => DailyMenu(
        id: id,
        menuDate: menuDate,
        cuisineId: cuisineId,
        cuisineName: cuisineName,
        mealType: mealType,
        notes: notes,
        isLocked: isLocked,
        items: items.map((e) => e.toEntity()).toList(),
      );

  static String _asDateString(Object? value) {
    final s = value?.toString() ?? '';
    if (s.length >= 10) return s.substring(0, 10);
    return s;
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }
}

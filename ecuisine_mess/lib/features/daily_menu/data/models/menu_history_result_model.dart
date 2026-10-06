import 'package:ecuisine_mess/features/daily_menu/data/models/daily_menu_model.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/menu_history_result.dart';

class MenuHistoryResultModel {
  const MenuHistoryResultModel({
    required this.total,
    required this.limit,
    required this.offset,
    required this.menus,
  });

  final int total;
  final int limit;
  final int offset;
  final List<DailyMenuModel> menus;

  factory MenuHistoryResultModel.fromJson(Map<String, dynamic> json) {
    final rawMenus = json['menus'] as List<dynamic>? ?? const [];
    return MenuHistoryResultModel(
      total: _asInt(json['total']),
      limit: _asInt(json['limit']),
      offset: _asInt(json['offset']),
      menus: rawMenus
          .map((e) => DailyMenuModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  MenuHistoryResult toEntity() => MenuHistoryResult(
        total: total,
        limit: limit,
        offset: offset,
        menus: menus.map((e) => e.toEntity()).toList(),
      );

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';

/// Parses `GET /dashboard/summary` defensively: windows and meals may be null,
/// numbers may arrive as strings (DECIMAL), and `served_by_cuisine` may be
/// missing on older servers.
class DashboardSummaryModel {
  const DashboardSummaryModel(this._entity);

  final DashboardSummary _entity;

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      DashboardSummary(
        serverTime: DateTime.tryParse(json['server_time']?.toString() ?? ''),
        currentMeal: _asString(json['current_meal']),
        nextMeal: _asString(json['next_meal']),
        currentWindow: _window(json['current_window']),
        nextWindow: _window(json['next_window']),
        servedToday: _servedToday(json['served_today']),
        menuReadiness: _list(json['menu_readiness'], _readiness),
        servedByCuisine: _list(json['served_by_cuisine'], _servedByCuisine),
      ),
    );
  }

  DashboardSummary toEntity() => _entity;

  static String? _asString(Object? v) {
    final s = v?.toString();
    return s == null || s.isEmpty ? null : s;
  }

  static int _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return num.tryParse(v?.toString() ?? '')?.toInt() ?? 0;
  }

  static bool _asBool(Object? v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  static Map<String, dynamic>? _asMap(Object? v) =>
      v is Map ? Map<String, dynamic>.from(v) : null;

  static List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) parse) {
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map) parse(Map<String, dynamic>.from(e)),
    ];
  }

  static MealWindow? _window(Object? v) {
    final m = _asMap(v);
    if (m == null) return null;
    return MealWindow(
      name: m['name']?.toString() ?? '',
      mealType: m['meal_type']?.toString() ?? '',
      startTime: m['start_time']?.toString() ?? '',
      endTime: m['end_time']?.toString() ?? '',
    );
  }

  static ServedToday _servedToday(Object? v) {
    final m = _asMap(v);
    if (m == null) return ServedToday.zero;
    final b = _asInt(m['BREAKFAST'] ?? m['B']);
    final l = _asInt(m['LUNCH'] ?? m['L']);
    final d = _asInt(m['DINNER'] ?? m['D']);
    return ServedToday(
      breakfast: b,
      lunch: l,
      dinner: d,
      total: m.containsKey('total') ? _asInt(m['total']) : b + l + d,
    );
  }

  static ServedByCuisine _servedByCuisine(Map<String, dynamic> m) {
    final b = _asInt(m['BREAKFAST']);
    final l = _asInt(m['LUNCH']);
    final d = _asInt(m['DINNER']);
    return ServedByCuisine(
      cuisineId: m['cuisine_id']?.toString() ?? '',
      cuisineName: m['cuisine_name']?.toString() ?? '',
      breakfast: b,
      lunch: l,
      dinner: d,
      total: m.containsKey('total') ? _asInt(m['total']) : b + l + d,
    );
  }

  static MenuReadiness _readiness(Map<String, dynamic> m) {
    final slots = _asMap(m['slots']) ?? const <String, dynamic>{};
    bool slot(String key) => _asBool(slots[key] ?? m[key]);
    final b = slot('BREAKFAST');
    final l = slot('LUNCH');
    final d = slot('DINNER');
    final totalSlots = m.containsKey('total_slots')
        ? _asInt(m['total_slots'])
        : 3;
    final filled = m.containsKey('filled_count')
        ? _asInt(m['filled_count'])
        : [b, l, d].where((x) => x).length;
    return MenuReadiness(
      cuisineId: m['cuisine_id']?.toString() ?? '',
      cuisineName: m['cuisine_name']?.toString() ?? '',
      status: _status(m['status']?.toString(), filled, totalSlots),
      filledCount: filled,
      totalSlots: totalSlots,
      breakfast: b,
      lunch: l,
      dinner: d,
    );
  }

  static ReadinessStatus _status(String? raw, int filled, int totalSlots) {
    switch (raw?.toUpperCase()) {
      case 'FULL':
        return ReadinessStatus.full;
      case 'PARTIAL':
        return ReadinessStatus.partial;
      case 'EMPTY':
        return ReadinessStatus.empty;
    }
    if (filled <= 0) return ReadinessStatus.empty;
    return filled >= totalSlots
        ? ReadinessStatus.full
        : ReadinessStatus.partial;
  }
}

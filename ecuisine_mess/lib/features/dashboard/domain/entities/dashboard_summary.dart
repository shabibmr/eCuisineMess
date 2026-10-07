import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';
import 'package:equatable/equatable.dart';

enum ReadinessStatus { full, partial, empty }

/// Served-bill counts for today, per meal type.
class ServedToday extends Equatable {
  const ServedToday({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.total,
  });

  static const zero = ServedToday(breakfast: 0, lunch: 0, dinner: 0, total: 0);

  final int breakfast;
  final int lunch;
  final int dinner;
  final int total;

  @override
  List<Object?> get props => [breakfast, lunch, dinner, total];
}

/// Served-bill counts for one cuisine (zero rows included for active cuisines).
class ServedByCuisine extends Equatable {
  const ServedByCuisine({
    required this.cuisineId,
    required this.cuisineName,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.total,
  });

  final String cuisineId;
  final String cuisineName;
  final int breakfast;
  final int lunch;
  final int dinner;
  final int total;

  @override
  List<Object?> get props => [
    cuisineId,
    cuisineName,
    breakfast,
    lunch,
    dinner,
    total,
  ];
}

/// Menu fill state of one cuisine for today.
class MenuReadiness extends Equatable {
  const MenuReadiness({
    required this.cuisineId,
    required this.cuisineName,
    required this.status,
    required this.filledCount,
    required this.totalSlots,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final String cuisineId;
  final String cuisineName;
  final ReadinessStatus status;
  final int filledCount;
  final int totalSlots;
  final bool breakfast;
  final bool lunch;
  final bool dinner;

  @override
  List<Object?> get props => [
    cuisineId,
    cuisineName,
    status,
    filledCount,
    totalSlots,
    breakfast,
    lunch,
    dinner,
  ];
}

class DashboardSummary extends Equatable {
  const DashboardSummary({
    this.serverTime,
    this.currentMeal,
    this.nextMeal,
    this.currentWindow,
    this.nextWindow,
    required this.servedToday,
    required this.menuReadiness,
    required this.servedByCuisine,
  });

  /// Server clock at response time; null if absent or unparseable.
  final DateTime? serverTime;
  final String? currentMeal;
  final String? nextMeal;
  final MealWindow? currentWindow;
  final MealWindow? nextWindow;
  final ServedToday servedToday;
  final List<MenuReadiness> menuReadiness;
  final List<ServedByCuisine> servedByCuisine;

  @override
  List<Object?> get props => [
    serverTime,
    currentMeal,
    nextMeal,
    currentWindow,
    nextWindow,
    servedToday,
    menuReadiness,
    servedByCuisine,
  ];
}

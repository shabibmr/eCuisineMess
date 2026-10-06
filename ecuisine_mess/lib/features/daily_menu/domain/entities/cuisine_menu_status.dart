import 'package:equatable/equatable.dart';

/// Fill readiness for one cuisine on a date (GET /menus/status readiness[]).
enum MenuFillStatus { empty, partial, full }

class CuisineMenuStatus extends Equatable {
  const CuisineMenuStatus({
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

  bool slotFilled(String mealType) {
    switch (mealType) {
      case 'BREAKFAST':
        return breakfast;
      case 'LUNCH':
        return lunch;
      case 'DINNER':
        return dinner;
      default:
        return false;
    }
  }

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

/// Wrapper for GET /menus/status.
class MenuDayStatus extends Equatable {
  const MenuDayStatus({
    required this.menuDate,
    required this.readiness,
  });

  final String menuDate;
  final List<CuisineMenuStatus> readiness;

  @override
  List<Object?> get props => [menuDate, readiness];
}

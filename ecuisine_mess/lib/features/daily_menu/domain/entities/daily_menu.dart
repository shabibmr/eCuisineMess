import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item.dart';
import 'package:equatable/equatable.dart';

/// One (menu_date, cuisine_id, meal_type) slot from GET /menus.
class DailyMenu extends Equatable {
  const DailyMenu({
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

  /// `BREAKFAST` | `LUNCH` | `DINNER`
  final String mealType;
  final String? notes;
  final bool isLocked;
  final List<DailyMenuItem> items;

  DailyMenu copyWith({
    String? id,
    String? menuDate,
    String? cuisineId,
    String? cuisineName,
    String? mealType,
    String? notes,
    bool? isLocked,
    List<DailyMenuItem>? items,
  }) {
    return DailyMenu(
      id: id ?? this.id,
      menuDate: menuDate ?? this.menuDate,
      cuisineId: cuisineId ?? this.cuisineId,
      cuisineName: cuisineName ?? this.cuisineName,
      mealType: mealType ?? this.mealType,
      notes: notes ?? this.notes,
      isLocked: isLocked ?? this.isLocked,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        menuDate,
        cuisineId,
        cuisineName,
        mealType,
        notes,
        isLocked,
        items,
      ];
}

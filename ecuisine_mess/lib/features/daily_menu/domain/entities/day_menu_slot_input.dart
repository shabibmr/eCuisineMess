import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item_input.dart';
import 'package:equatable/equatable.dart';

/// One slot inside POST /menus/save-day `menus[]`.
class DayMenuSlotInput extends Equatable {
  const DayMenuSlotInput({
    required this.cuisineId,
    required this.mealType,
    this.items = const [],
    this.notes,
    this.isLocked = false,
  });

  final String cuisineId;

  /// `BREAKFAST` | `LUNCH` | `DINNER`
  final String mealType;
  final List<DailyMenuItemInput> items;
  final String? notes;
  final bool isLocked;

  @override
  List<Object?> get props => [cuisineId, mealType, items, notes, isLocked];
}

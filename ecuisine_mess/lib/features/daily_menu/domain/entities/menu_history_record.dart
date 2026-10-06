import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item.dart';
import 'package:equatable/equatable.dart';

class MenuHistoryRecord extends Equatable {
  const MenuHistoryRecord({
    required this.date,
    required this.cuisineId,
    required this.cuisineName,
    this.breakfastMenu,
    this.lunchMenu,
    this.dinnerMenu,
  });

  final String date;
  final String cuisineId;
  final String cuisineName;
  final DailyMenu? breakfastMenu;
  final DailyMenu? lunchMenu;
  final DailyMenu? dinnerMenu;

  List<DailyMenuItem> get breakfastItems => breakfastMenu?.items ?? const [];
  List<DailyMenuItem> get lunchItems => lunchMenu?.items ?? const [];
  List<DailyMenuItem> get dinnerItems => dinnerMenu?.items ?? const [];

  int get breakfastCount => breakfastItems.length;
  int get lunchCount => lunchItems.length;
  int get dinnerCount => dinnerItems.length;
  int get totalItemsCount => breakfastCount + lunchCount + dinnerCount;

  bool get isLocked =>
      (breakfastMenu?.isLocked ?? false) ||
      (lunchMenu?.isLocked ?? false) ||
      (dinnerMenu?.isLocked ?? false);

  @override
  List<Object?> get props => [
        date,
        cuisineId,
        cuisineName,
        breakfastMenu,
        lunchMenu,
        dinnerMenu,
      ];
}

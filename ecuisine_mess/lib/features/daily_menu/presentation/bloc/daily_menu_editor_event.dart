part of 'daily_menu_editor_bloc.dart';

sealed class DailyMenuEditorEvent extends Equatable {
  const DailyMenuEditorEvent();

  @override
  List<Object?> get props => [];
}

final class DailyMenuEditorStarted extends DailyMenuEditorEvent {
  const DailyMenuEditorStarted({
    this.menuDate,
    this.cuisineId,
    this.mealType,
  });

  final String? menuDate;
  final String? cuisineId;
  final String? mealType;

  @override
  List<Object?> get props => [menuDate, cuisineId, mealType];
}

final class DailyMenuDateChanged extends DailyMenuEditorEvent {
  const DailyMenuDateChanged(this.menuDate);

  final String menuDate;

  @override
  List<Object?> get props => [menuDate];
}

final class DailyMenuDateShifted extends DailyMenuEditorEvent {
  const DailyMenuDateShifted(this.days);

  final int days;

  @override
  List<Object?> get props => [days];
}

final class DailyMenuJumpToday extends DailyMenuEditorEvent {
  const DailyMenuJumpToday();
}

final class DailyMenuPendingDateResolved extends DailyMenuEditorEvent {
  const DailyMenuPendingDateResolved({required this.save});

  final bool save;

  @override
  List<Object?> get props => [save];
}

final class DailyMenuPendingDateCancelled extends DailyMenuEditorEvent {
  const DailyMenuPendingDateCancelled();
}

final class DailyMenuCuisineSelected extends DailyMenuEditorEvent {
  const DailyMenuCuisineSelected(this.cuisineId);

  final String cuisineId;

  @override
  List<Object?> get props => [cuisineId];
}

final class DailyMenuMealSelected extends DailyMenuEditorEvent {
  const DailyMenuMealSelected(this.mealType);

  final String mealType;

  @override
  List<Object?> get props => [mealType];
}

final class DailyMenuItemAdded extends DailyMenuEditorEvent {
  const DailyMenuItemAdded(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class DailyMenuItemsAddAllMapped extends DailyMenuEditorEvent {
  const DailyMenuItemsAddAllMapped();
}

final class DailyMenuItemRemoved extends DailyMenuEditorEvent {
  const DailyMenuItemRemoved(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class DailyMenuItemQtyChanged extends DailyMenuEditorEvent {
  const DailyMenuItemQtyChanged({
    required this.itemId,
    required this.quantity,
  });

  final String itemId;
  final double quantity;

  @override
  List<Object?> get props => [itemId, quantity];
}

final class DailyMenuResetRequested extends DailyMenuEditorEvent {
  const DailyMenuResetRequested();
}

final class DailyMenuSaveRequested extends DailyMenuEditorEvent {
  const DailyMenuSaveRequested();
}

final class DailyMenuCopyFromDateRequested extends DailyMenuEditorEvent {
  const DailyMenuCopyFromDateRequested({
    required this.fromDate,
    this.overwrite = false,
  });

  final String fromDate;
  final bool overwrite;

  @override
  List<Object?> get props => [fromDate, overwrite];
}

final class DailyMenuCopyMealRequested extends DailyMenuEditorEvent {
  const DailyMenuCopyMealRequested({required this.toCuisineIds});

  final List<String> toCuisineIds;

  @override
  List<Object?> get props => [toCuisineIds];
}

final class DailyMenuNoticeConsumed extends DailyMenuEditorEvent {
  const DailyMenuNoticeConsumed();
}

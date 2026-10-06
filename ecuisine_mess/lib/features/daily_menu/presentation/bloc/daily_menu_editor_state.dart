part of 'daily_menu_editor_bloc.dart';

final class MenuSlotLine extends Equatable {
  const MenuSlotLine({
    required this.itemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    this.notes,
    this.categoryId,
    this.category,
    this.uomId,
  });

  factory MenuSlotLine.fromEntity(DailyMenuItem item) {
    return MenuSlotLine(
      itemId: item.itemId,
      itemName: item.itemName,
      unit: item.unit,
      quantity: item.quantity,
      notes: item.notes,
      categoryId: item.categoryId,
      category: item.category,
      uomId: item.uomId,
    );
  }

  final String itemId;
  final String itemName;
  final String unit;
  final double quantity;
  final String? notes;
  final String? categoryId;
  final String? category;
  final String? uomId;

  MenuSlotLine copyWith({
    double? quantity,
    String? notes,
  }) {
    return MenuSlotLine(
      itemId: itemId,
      itemName: itemName,
      unit: unit,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      categoryId: categoryId,
      category: category,
      uomId: uomId,
    );
  }

  @override
  List<Object?> get props => [
        itemId,
        itemName,
        unit,
        quantity,
        notes,
        categoryId,
        category,
        uomId,
      ];
}

final class MenuSlotEdit extends Equatable {
  const MenuSlotEdit({
    this.menuId,
    required this.cuisineId,
    required this.mealType,
    this.notes,
    this.isLocked = false,
    this.items = const [],
  });

  factory MenuSlotEdit.fromDailyMenu(DailyMenu menu) {
    return MenuSlotEdit(
      menuId: menu.id,
      cuisineId: menu.cuisineId,
      mealType: menu.mealType.toUpperCase(),
      notes: menu.notes,
      isLocked: menu.isLocked,
      items: menu.items.map(MenuSlotLine.fromEntity).toList(),
    );
  }

  final String? menuId;
  final String cuisineId;
  final String mealType;
  final String? notes;
  final bool isLocked;
  final List<MenuSlotLine> items;

  MenuSlotEdit copyWith({
    String? menuId,
    String? notes,
    bool? isLocked,
    List<MenuSlotLine>? items,
  }) {
    return MenuSlotEdit(
      menuId: menuId ?? this.menuId,
      cuisineId: cuisineId,
      mealType: mealType,
      notes: notes ?? this.notes,
      isLocked: isLocked ?? this.isLocked,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props =>
      [menuId, cuisineId, mealType, notes, isLocked, items];
}

final class DailyMenuEditorState extends Equatable {
  const DailyMenuEditorState({
    this.status = Status.initial,
    this.menuDate = '',
    this.isPastDate = false,
    this.cuisines = const [],
    this.selectedCuisineId,
    this.selectedMealType = 'BREAKFAST',
    this.slots = const [],
    this.mappedItems = const [],
    this.dirty = false,
    this.pendingDate,
    this.error,
    this.notice,
    this.conflictCode,
  });

  final Status status;
  final String menuDate;
  final bool isPastDate;
  final List<CuisineOption> cuisines;
  final String? selectedCuisineId;
  final String selectedMealType;
  final List<MenuSlotEdit> slots;
  final List<CuisineItemMapping> mappedItems;
  final bool dirty;
  final String? pendingDate;
  final String? error;
  final String? notice;
  final String? conflictCode;

  bool get isReadOnly {
    if (isPastDate) return true;
    final slot = currentSlot;
    return slot != null && slot.isLocked;
  }

  bool get isCurrentMealLocked {
    final slot = currentSlot;
    return slot != null && slot.isLocked;
  }

  MenuSlotEdit? get currentSlot {
    final cuisineId = selectedCuisineId;
    if (cuisineId == null) return null;
    return slotFor(cuisineId, selectedMealType);
  }

  List<CuisineMenuStatus> get readiness =>
      DailyMenuEditorBloc.deriveReadiness(cuisines, slots);

  List<CuisineItemMapping> get availableMappedItems {
    final current = currentSlot;
    if (current == null) return mappedItems;
    final used = current.items.map((i) => i.itemId).toSet();
    return mappedItems.where((m) => !used.contains(m.itemId)).toList();
  }

  int itemCountForMeal(String mealType) {
    final cuisineId = selectedCuisineId;
    if (cuisineId == null) return 0;
    final slot = slotFor(cuisineId, mealType);
    return slot?.items.length ?? 0;
  }

  MenuSlotEdit? slotFor(String cuisineId, String mealType) {
    final meal = mealType.toUpperCase();
    for (final slot in slots) {
      if (slot.cuisineId == cuisineId && slot.mealType == meal) {
        return slot;
      }
    }
    return null;
  }

  DailyMenuEditorState copyWith({
    Status? status,
    String? menuDate,
    bool? isPastDate,
    List<CuisineOption>? cuisines,
    String? selectedCuisineId,
    bool clearSelectedCuisine = false,
    String? selectedMealType,
    List<MenuSlotEdit>? slots,
    List<CuisineItemMapping>? mappedItems,
    bool? dirty,
    String? pendingDate,
    bool clearPendingDate = false,
    String? error,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
    String? conflictCode,
    bool clearConflict = false,
  }) {
    return DailyMenuEditorState(
      status: status ?? this.status,
      menuDate: menuDate ?? this.menuDate,
      isPastDate: isPastDate ?? this.isPastDate,
      cuisines: cuisines ?? this.cuisines,
      selectedCuisineId: clearSelectedCuisine
          ? null
          : (selectedCuisineId ?? this.selectedCuisineId),
      selectedMealType: selectedMealType ?? this.selectedMealType,
      slots: slots ?? this.slots,
      mappedItems: mappedItems ?? this.mappedItems,
      dirty: dirty ?? this.dirty,
      pendingDate:
          clearPendingDate ? null : (pendingDate ?? this.pendingDate),
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
      conflictCode:
          clearConflict ? null : (conflictCode ?? this.conflictCode),
    );
  }

  @override
  List<Object?> get props => [
        status,
        menuDate,
        isPastDate,
        cuisines,
        selectedCuisineId,
        selectedMealType,
        slots,
        mappedItems,
        dirty,
        pendingDate,
        error,
        notice,
        conflictCode,
      ];
}

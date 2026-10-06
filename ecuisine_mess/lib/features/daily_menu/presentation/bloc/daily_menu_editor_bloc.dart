import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/get_cuisine.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/cuisine_menu_status.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/daily_menu_item_input.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/entities/day_menu_slot_input.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/copy_from_date.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/copy_meal_to_cuisines.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/get_day_menu.dart';
import 'package:ecuisine_mess/features/daily_menu/domain/usecases/save_day_menu.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/get_cuisine_options.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'daily_menu_editor_event.dart';
part 'daily_menu_editor_state.dart';

class DailyMenuEditorBloc
    extends Bloc<DailyMenuEditorEvent, DailyMenuEditorState> {
  DailyMenuEditorBloc({
    required GetCuisineOptions getCuisineOptions,
    required GetDayMenu getDayMenu,
    required SaveDayMenu saveDayMenu,
    required CopyFromDate copyFromDate,
    required CopyMealToCuisines copyMealToCuisines,
    required GetCuisine getCuisine,
  })  : _getCuisineOptions = getCuisineOptions,
        _getDayMenu = getDayMenu,
        _saveDayMenu = saveDayMenu,
        _copyFromDate = copyFromDate,
        _copyMealToCuisines = copyMealToCuisines,
        _getCuisine = getCuisine,
        super(const DailyMenuEditorState()) {
    on<DailyMenuEditorStarted>(_onStarted);
    on<DailyMenuDateChanged>(_onDateChanged);
    on<DailyMenuDateShifted>(_onDateShifted);
    on<DailyMenuJumpToday>(_onJumpToday);
    on<DailyMenuPendingDateResolved>(
      _onPendingDateResolved,
      transformer: droppable(),
    );
    on<DailyMenuPendingDateCancelled>(_onPendingDateCancelled);
    on<DailyMenuCuisineSelected>(_onCuisineSelected);
    on<DailyMenuMealSelected>(_onMealSelected);
    on<DailyMenuItemAdded>(_onItemAdded);
    on<DailyMenuItemsAddAllMapped>(_onAddAllMapped);
    on<DailyMenuItemRemoved>(_onItemRemoved);
    on<DailyMenuItemQtyChanged>(_onItemQtyChanged);
    on<DailyMenuResetRequested>(_onReset);
    on<DailyMenuSaveRequested>(_onSave, transformer: droppable());
    on<DailyMenuCopyFromDateRequested>(
      _onCopyFromDate,
      transformer: droppable(),
    );
    on<DailyMenuCopyMealRequested>(_onCopyMeal, transformer: droppable());
    on<DailyMenuNoticeConsumed>(_onNoticeConsumed);
  }

  static const mealTypes = ['BREAKFAST', 'LUNCH', 'DINNER'];

  final GetCuisineOptions _getCuisineOptions;
  final GetDayMenu _getDayMenu;
  final SaveDayMenu _saveDayMenu;
  final CopyFromDate _copyFromDate;
  final CopyMealToCuisines _copyMealToCuisines;
  final GetCuisine _getCuisine;

  Future<void> _onStarted(
    DailyMenuEditorStarted event,
    Emitter<DailyMenuEditorState> emit,
  ) async {
    final date = (event.menuDate != null && event.menuDate!.isNotEmpty)
        ? event.menuDate!
        : formatDate(DateTime.now());
    final meal = _normalizeMeal(event.mealType) ?? 'BREAKFAST';

    emit(
      state.copyWith(
        status: Status.loading,
        menuDate: date,
        selectedMealType: meal,
        clearError: true,
        clearPendingDate: true,
      ),
    );

    try {
      final cuisines = await _getCuisineOptions(
        const GetCuisineOptionsParams(),
      );
      final active = cuisines.where((c) => c.isActive).toList();
      final selectedId = _resolveCuisineId(event.cuisineId, active);

      final menus = await _getDayMenu(GetDayMenuParams(menuDate: date));
      final slots = buildSlots(active, menus);

      List<CuisineItemMapping> mapped = const [];
      if (selectedId != null) {
        mapped = await _loadMapped(selectedId);
      }

      emit(
        state.copyWith(
          status: Status.success,
          menuDate: date,
          isPastDate: isPastDate(date),
          cuisines: active,
          selectedCuisineId: selectedId,
          selectedMealType: meal,
          slots: slots,
          mappedItems: mapped,
          dirty: false,
          clearPendingDate: true,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onDateChanged(
    DailyMenuDateChanged event,
    Emitter<DailyMenuEditorState> emit,
  ) async {
    final next = event.menuDate;
    if (next == state.menuDate) return;
    if (state.dirty) {
      emit(state.copyWith(pendingDate: next));
      return;
    }
    await _loadDate(next, emit: emit);
  }

  void _onDateShifted(
    DailyMenuDateShifted event,
    Emitter<DailyMenuEditorState> emit,
  ) {
    add(DailyMenuDateChanged(shiftDate(state.menuDate, event.days)));
  }

  void _onJumpToday(
    DailyMenuJumpToday event,
    Emitter<DailyMenuEditorState> emit,
  ) {
    add(DailyMenuDateChanged(formatDate(DateTime.now())));
  }

  Future<void> _onPendingDateResolved(
    DailyMenuPendingDateResolved event,
    Emitter<DailyMenuEditorState> emit,
  ) async {
    final pending = state.pendingDate;
    if (pending == null) return;
    if (event.save) {
      final ok = await _save(emit);
      if (!ok) return;
    }
    await _loadDate(pending, emit: emit);
  }

  void _onPendingDateCancelled(
    DailyMenuPendingDateCancelled event,
    Emitter<DailyMenuEditorState> emit,
  ) {
    emit(state.copyWith(clearPendingDate: true));
  }

  Future<void> _onCuisineSelected(
    DailyMenuCuisineSelected event,
    Emitter<DailyMenuEditorState> emit,
  ) async {
    if (event.cuisineId == state.selectedCuisineId) return;
    emit(
      state.copyWith(
        selectedCuisineId: event.cuisineId,
        clearError: true,
      ),
    );
    try {
      final mapped = await _loadMapped(event.cuisineId);
      emit(state.copyWith(mappedItems: mapped, clearError: true));
    } on Failure catch (e) {
      emit(state.copyWith(error: e.message, mappedItems: const []));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), mappedItems: const []));
    }
  }

  void _onMealSelected(
    DailyMenuMealSelected event,
    Emitter<DailyMenuEditorState> emit,
  ) {
    final meal = _normalizeMeal(event.mealType);
    if (meal == null || meal == state.selectedMealType) return;
    emit(state.copyWith(selectedMealType: meal, clearError: true));
  }

  void _onItemAdded(
    DailyMenuItemAdded event,
    Emitter<DailyMenuEditorState> emit,
  ) {
    if (state.isReadOnly) return;
    final cuisineId = state.selectedCuisineId;
    if (cuisineId == null) return;

    final slot = state.slotFor(cuisineId, state.selectedMealType);
    if (slot == null || slot.isLocked) return;
    if (slot.items.any((i) => i.itemId == event.itemId)) {
      emit(state.copyWith(error: 'Item already on this meal'));
      return;
    }

    CuisineItemMapping? mapping;
    for (final m in state.mappedItems) {
      if (m.itemId == event.itemId) {
        mapping = m;
        break;
      }
    }
    if (mapping == null) {
      emit(state.copyWith(error: 'Item is not mapped to this cuisine'));
      return;
    }

    final line = MenuSlotLine(
      itemId: mapping.itemId,
      itemName: mapping.itemName,
      unit: mapping.unit,
      quantity: mapping.defaultQty > 0 ? mapping.defaultQty : 1,
      categoryId: mapping.categoryId,
      category: mapping.category,
      uomId: mapping.uomId,
    );
    emit(
      state.copyWith(
        slots: _replaceSlot(slot.copyWith(items: [...slot.items, line])),
        dirty: true,
        clearError: true,
      ),
    );
  }

  void _onAddAllMapped(
    DailyMenuItemsAddAllMapped event,
    Emitter<DailyMenuEditorState> emit,
  ) {
    if (state.isReadOnly) return;
    final cuisineId = state.selectedCuisineId;
    if (cuisineId == null) return;

    final slot = state.slotFor(cuisineId, state.selectedMealType);
    if (slot == null || slot.isLocked) return;

    final existing = slot.items.map((i) => i.itemId).toSet();
    final toAdd = <MenuSlotLine>[];
    for (final mapping in state.mappedItems) {
      if (existing.contains(mapping.itemId)) continue;
      toAdd.add(
        MenuSlotLine(
          itemId: mapping.itemId,
          itemName: mapping.itemName,
          unit: mapping.unit,
          quantity: mapping.defaultQty > 0 ? mapping.defaultQty : 1,
          categoryId: mapping.categoryId,
          category: mapping.category,
          uomId: mapping.uomId,
        ),
      );
    }
    if (toAdd.isEmpty) {
      emit(state.copyWith(notice: 'All mapped items are already on this meal'));
      return;
    }
    emit(
      state.copyWith(
        slots: _replaceSlot(slot.copyWith(items: [...slot.items, ...toAdd])),
        dirty: true,
        notice: 'Added ${toAdd.length} mapped item(s)',
        clearError: true,
      ),
    );
  }

  void _onItemRemoved(
    DailyMenuItemRemoved event,
    Emitter<DailyMenuEditorState> emit,
  ) {
    if (state.isReadOnly) return;
    final cuisineId = state.selectedCuisineId;
    if (cuisineId == null) return;
    final slot = state.slotFor(cuisineId, state.selectedMealType);
    if (slot == null || slot.isLocked) return;

    final nextItems =
        slot.items.where((i) => i.itemId != event.itemId).toList();
    emit(
      state.copyWith(
        slots: _replaceSlot(slot.copyWith(items: nextItems)),
        dirty: true,
        clearError: true,
      ),
    );
  }

  void _onItemQtyChanged(
    DailyMenuItemQtyChanged event,
    Emitter<DailyMenuEditorState> emit,
  ) {
    if (state.isReadOnly) return;
    final cuisineId = state.selectedCuisineId;
    if (cuisineId == null) return;
    final slot = state.slotFor(cuisineId, state.selectedMealType);
    if (slot == null || slot.isLocked) return;

    final qty = event.quantity <= 0 ? 1.0 : event.quantity;
    final nextItems = slot.items.map((i) {
      if (i.itemId != event.itemId) return i;
      return i.copyWith(quantity: qty);
    }).toList();
    emit(
      state.copyWith(
        slots: _replaceSlot(slot.copyWith(items: nextItems)),
        dirty: true,
        clearError: true,
      ),
    );
  }

  Future<void> _onReset(
    DailyMenuResetRequested event,
    Emitter<DailyMenuEditorState> emit,
  ) async {
    if (state.isPastDate) return;
    await _loadDate(
      state.menuDate,
      emit: emit,
      notice: 'Menu reset to saved state',
    );
  }

  Future<void> _onSave(
    DailyMenuSaveRequested event,
    Emitter<DailyMenuEditorState> emit,
  ) async {
    await _save(emit);
  }

  Future<void> _onCopyFromDate(
    DailyMenuCopyFromDateRequested event,
    Emitter<DailyMenuEditorState> emit,
  ) async {
    if (state.isPastDate) return;
    if (event.fromDate == state.menuDate) {
      emit(state.copyWith(error: 'Source date must differ from current date'));
      return;
    }
    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      final result = await _copyFromDate(
        CopyFromDateParams(
          fromDate: event.fromDate,
          toDate: state.menuDate,
          overwrite: event.overwrite,
        ),
      );
      await _loadDate(
        state.menuDate,
        emit: emit,
        notice: result.message ??
            'Copied ${result.copiedSlotsCount} slot(s) from ${event.fromDate}',
      );
    } on ConflictFailure catch (e) {
      emit(
        state.copyWith(
          status: Status.failure,
          error: e.message,
          conflictCode: e.code,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onCopyMeal(
    DailyMenuCopyMealRequested event,
    Emitter<DailyMenuEditorState> emit,
  ) async {
    if (state.isReadOnly) return;
    final cuisineId = state.selectedCuisineId;
    if (cuisineId == null) return;
    final slot = state.slotFor(cuisineId, state.selectedMealType);
    if (slot == null || slot.items.isEmpty) {
      emit(state.copyWith(error: 'Current meal has no items to copy'));
      return;
    }
    if (event.toCuisineIds.isEmpty) {
      emit(state.copyWith(error: 'Select at least one target cuisine'));
      return;
    }

    // Persist local edits first so API copy sees current meal.
    if (state.dirty) {
      final ok = await _save(emit);
      if (!ok) return;
    }

    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      final result = await _copyMealToCuisines(
        CopyMealToCuisinesParams(
          menuDate: state.menuDate,
          fromCuisineId: cuisineId,
          mealType: state.selectedMealType,
          toCuisineIds: event.toCuisineIds,
        ),
      );
      final skipped = result.skipped.length;
      final notice = result.message ??
          'Copied to ${result.copiedCuisines.length} cuisine(s)'
              '${skipped > 0 ? ' ($skipped skipped)' : ''}';
      await _loadDate(state.menuDate, emit: emit, notice: notice);
    } on ConflictFailure catch (e) {
      emit(
        state.copyWith(
          status: Status.failure,
          error: e.message,
          conflictCode: e.code,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  void _onNoticeConsumed(
    DailyMenuNoticeConsumed event,
    Emitter<DailyMenuEditorState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }

  Future<void> _loadDate(
    String date, {
    required Emitter<DailyMenuEditorState> emit,
    String? notice,
  }) async {
    emit(
      state.copyWith(
        status: Status.loading,
        menuDate: date,
        isPastDate: isPastDate(date),
        clearPendingDate: true,
        clearError: true,
        clearConflict: true,
      ),
    );
    try {
      final menus = await _getDayMenu(GetDayMenuParams(menuDate: date));
      final slots = buildSlots(state.cuisines, menus);
      final cuisineId = _resolveCuisineId(
        state.selectedCuisineId,
        state.cuisines,
      );
      List<CuisineItemMapping> mapped = const [];
      if (cuisineId != null) {
        mapped = await _loadMapped(cuisineId);
      }
      emit(
        state.copyWith(
          status: Status.success,
          menuDate: date,
          isPastDate: isPastDate(date),
          selectedCuisineId: cuisineId,
          slots: slots,
          mappedItems: mapped,
          dirty: false,
          notice: notice,
          clearPendingDate: true,
          clearError: true,
          clearConflict: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<bool> _save(Emitter<DailyMenuEditorState> emit) async {
    if (state.isPastDate) {
      emit(
        state.copyWith(
          status: Status.failure,
          error: 'Past dates are read-only',
          conflictCode: 'PAST_DATE_READ_ONLY',
        ),
      );
      return false;
    }

    final payload = <DayMenuSlotInput>[];
    for (final slot in state.slots) {
      if (slot.isLocked) continue;
      final hasItems = slot.items.isNotEmpty;
      final existed = slot.menuId != null && slot.menuId!.isNotEmpty;
      if (!hasItems && !existed) continue;
      payload.add(
        DayMenuSlotInput(
          cuisineId: slot.cuisineId,
          mealType: slot.mealType,
          notes: slot.notes,
          isLocked: false,
          items: slot.items
              .map(
                (i) => DailyMenuItemInput(
                  itemId: i.itemId,
                  quantity: i.quantity,
                  notes: i.notes,
                ),
              )
              .toList(),
        ),
      );
    }

    if (payload.isEmpty && !state.dirty) {
      emit(state.copyWith(notice: 'Nothing to save', clearError: true));
      return true;
    }

    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      final result = await _saveDayMenu(
        SaveDayMenuParams(menuDate: state.menuDate, menus: payload),
      );
      await _loadDate(
        state.menuDate,
        emit: emit,
        notice: result.message ??
            'Saved ${result.savedSlotsCount} slot(s) for ${state.menuDate}',
      );
      return true;
    } on ConflictFailure catch (e) {
      emit(
        state.copyWith(
          status: Status.failure,
          error: e.message,
          conflictCode: e.code,
        ),
      );
      return false;
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
      return false;
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
      return false;
    }
  }

  Future<List<CuisineItemMapping>> _loadMapped(String cuisineId) async {
    final cuisine = await _getCuisine(cuisineId);
    final items = [...cuisine.items]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  List<MenuSlotEdit> _replaceSlot(MenuSlotEdit updated) {
    return state.slots.map((s) {
      if (s.cuisineId == updated.cuisineId &&
          s.mealType == updated.mealType) {
        return updated;
      }
      return s;
    }).toList();
  }

  static String? _resolveCuisineId(
    String? preferred,
    List<CuisineOption> active,
  ) {
    if (active.isEmpty) return null;
    if (preferred != null &&
        preferred.isNotEmpty &&
        active.any((c) => c.id == preferred)) {
      return preferred;
    }
    return active.first.id;
  }

  static String? _normalizeMeal(String? mealType) {
    if (mealType == null || mealType.isEmpty) return null;
    final upper = mealType.toUpperCase();
    switch (upper) {
      case 'B':
      case 'BREAKFAST':
        return 'BREAKFAST';
      case 'L':
      case 'LUNCH':
        return 'LUNCH';
      case 'D':
      case 'DINNER':
        return 'DINNER';
      default:
        return mealTypes.contains(upper) ? upper : null;
    }
  }

  /// Visible for unit tests.
  static String formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Visible for unit tests.
  static String shiftDate(String isoDate, int days) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return isoDate;
    final next = DateTime(y, m, d).add(Duration(days: days));
    return formatDate(next);
  }

  /// Visible for unit tests.
  static bool isPastDate(String isoDate, {DateTime? now}) {
    final today = formatDate(now ?? DateTime.now());
    return isoDate.compareTo(today) < 0;
  }

  /// Visible for unit tests.
  static List<MenuSlotEdit> buildSlots(
    List<CuisineOption> cuisines,
    List<DailyMenu> menus,
  ) {
    final byKey = <String, DailyMenu>{};
    for (final menu in menus) {
      byKey[slotKey(menu.cuisineId, menu.mealType)] = menu;
    }

    final slots = <MenuSlotEdit>[];
    for (final cuisine in cuisines) {
      for (final meal in mealTypes) {
        final existing = byKey[slotKey(cuisine.id, meal)];
        if (existing != null) {
          slots.add(MenuSlotEdit.fromDailyMenu(existing));
        } else {
          slots.add(
            MenuSlotEdit(
              cuisineId: cuisine.id,
              mealType: meal,
              items: const [],
            ),
          );
        }
      }
    }
    return slots;
  }

  static String slotKey(String cuisineId, String mealType) =>
      '$cuisineId|${mealType.toUpperCase()}';

  /// Visible for unit tests.
  static List<CuisineMenuStatus> deriveReadiness(
    List<CuisineOption> cuisines,
    List<MenuSlotEdit> slots,
  ) {
    return cuisines.map((c) {
      bool filled(String meal) {
        for (final slot in slots) {
          if (slot.cuisineId == c.id && slot.mealType == meal) {
            return slot.items.isNotEmpty;
          }
        }
        return false;
      }

      final breakfast = filled('BREAKFAST');
      final lunch = filled('LUNCH');
      final dinner = filled('DINNER');
      final count =
          (breakfast ? 1 : 0) + (lunch ? 1 : 0) + (dinner ? 1 : 0);
      final status = count == 3
          ? MenuFillStatus.full
          : count > 0
              ? MenuFillStatus.partial
              : MenuFillStatus.empty;
      return CuisineMenuStatus(
        cuisineId: c.id,
        cuisineName: c.name,
        status: status,
        filledCount: count,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
      );
    }).toList();
  }
}

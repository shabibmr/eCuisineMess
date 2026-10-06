import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';
import 'package:ecuisine_mess/features/meal_times/domain/usecases/get_meal_times.dart';
import 'package:ecuisine_mess/features/meal_times/domain/usecases/save_meal_time.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/get_cuisine_options.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'meal_time_settings_event.dart';
part 'meal_time_settings_state.dart';

class MealTimeSettingsBloc
    extends Bloc<MealTimeSettingsEvent, MealTimeSettingsState> {
  MealTimeSettingsBloc({
    required GetCuisineOptions getCuisineOptions,
    required GetMealTimes getMealTimes,
    required SaveMealTime saveMealTime,
  })  : _getCuisineOptions = getCuisineOptions,
        _getMealTimes = getMealTimes,
        _saveMealTime = saveMealTime,
        super(const MealTimeSettingsState()) {
    on<MealTimeSettingsStarted>(_onStarted);
    on<MealTimeCuisineSelected>(_onCuisineSelected);
    on<MealTimePendingCuisineResolved>(
      _onPendingCuisineResolved,
      transformer: droppable(),
    );
    on<MealTimePendingCuisineCancelled>(_onPendingCuisineCancelled);
    on<MealTimeRowEdited>(_onRowEdited);
    on<MealTimeSaveRequested>(_onSave, transformer: droppable());
    on<MealTimeSettingsNoticeConsumed>(_onNoticeConsumed);
  }

  static const _mealOrder = ['BREAKFAST', 'LUNCH', 'DINNER'];

  final GetCuisineOptions _getCuisineOptions;
  final GetMealTimes _getMealTimes;
  final SaveMealTime _saveMealTime;

  Future<void> _onStarted(
    MealTimeSettingsStarted event,
    Emitter<MealTimeSettingsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, clearError: true));
    try {
      final cuisines = await _getCuisineOptions(
        const GetCuisineOptionsParams(),
      );
      final active = cuisines.where((c) => c.isActive).toList();
      if (active.isEmpty) {
        emit(
          state.copyWith(
            status: Status.success,
            cuisines: cuisines,
            rows: const [],
            clearSelectedCuisine: true,
            clearError: true,
          ),
        );
        return;
      }
      final selectedId = active.first.id;
      final rows = await _loadRows(selectedId);
      emit(
        state.copyWith(
          status: Status.success,
          cuisines: cuisines,
          selectedCuisineId: selectedId,
          rows: rows,
          clearPendingCuisine: true,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onCuisineSelected(
    MealTimeCuisineSelected event,
    Emitter<MealTimeSettingsState> emit,
  ) async {
    if (event.cuisineId == state.selectedCuisineId) return;
    if (state.isDirty) {
      emit(state.copyWith(pendingCuisineId: event.cuisineId));
      return;
    }
    await _switchCuisine(event.cuisineId, emit);
  }

  Future<void> _onPendingCuisineResolved(
    MealTimePendingCuisineResolved event,
    Emitter<MealTimeSettingsState> emit,
  ) async {
    final pending = state.pendingCuisineId;
    if (pending == null) return;
    if (event.save) {
      final ok = await _saveDirtyRows(emit);
      if (!ok) return;
    }
    await _switchCuisine(pending, emit);
  }

  void _onPendingCuisineCancelled(
    MealTimePendingCuisineCancelled event,
    Emitter<MealTimeSettingsState> emit,
  ) {
    emit(state.copyWith(clearPendingCuisine: true));
  }

  void _onRowEdited(
    MealTimeRowEdited event,
    Emitter<MealTimeSettingsState> emit,
  ) {
    final next = state.rows.map((row) {
      if (row.id != event.id) return row;
      return row.copyWith(
        name: event.name,
        startTime: event.startTime,
        endTime: event.endTime,
        isActive: event.isActive,
        dirty: true,
      );
    }).toList();
    emit(
      state.copyWith(
        rows: _withValidation(next),
        clearError: true,
      ),
    );
  }

  Future<void> _onSave(
    MealTimeSaveRequested event,
    Emitter<MealTimeSettingsState> emit,
  ) async {
    await _saveDirtyRows(emit, onlyId: event.rowId);
  }

  void _onNoticeConsumed(
    MealTimeSettingsNoticeConsumed event,
    Emitter<MealTimeSettingsState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }

  Future<void> _switchCuisine(
    String cuisineId,
    Emitter<MealTimeSettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: Status.loading,
        selectedCuisineId: cuisineId,
        clearPendingCuisine: true,
        clearError: true,
      ),
    );
    try {
      final rows = await _loadRows(cuisineId);
      emit(
        state.copyWith(
          status: Status.success,
          rows: rows,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<List<MealTimeRowEdit>> _loadRows(String cuisineId) async {
    final list = await _getMealTimes(GetMealTimesParams(cuisineId: cuisineId));
    final sorted = [...list]..sort((a, b) {
        final ai = _mealOrder.indexOf(a.mealType.toUpperCase());
        final bi = _mealOrder.indexOf(b.mealType.toUpperCase());
        final ao = ai < 0 ? 99 : ai;
        final bo = bi < 0 ? 99 : bi;
        return ao.compareTo(bo);
      });
    return _withValidation(
      sorted.map(MealTimeRowEdit.fromEntity).toList(),
    );
  }

  Future<bool> _saveDirtyRows(
    Emitter<MealTimeSettingsState> emit, {
    String? onlyId,
  }) async {
    final validated = _withValidation(state.rows);
    final hasLocalErrors = validated.any(
      (r) =>
          r.dirty &&
          (onlyId == null || r.id == onlyId) &&
          r.validationError != null,
    );
    if (hasLocalErrors) {
      emit(
        state.copyWith(
          rows: validated,
          status: Status.failure,
          error: 'Fix invalid meal windows before saving',
        ),
      );
      return false;
    }

    final targets = validated
        .where((r) => r.dirty && (onlyId == null || r.id == onlyId))
        .toList();
    if (targets.isEmpty) {
      emit(state.copyWith(notice: 'Nothing to save', clearError: true));
      return true;
    }

    emit(
      state.copyWith(
        status: Status.submitting,
        rows: validated,
        clearError: true,
      ),
    );
    try {
      for (final row in targets) {
        await _saveMealTime(
          SaveMealTimeParams(
            id: row.id,
            name: row.name.trim(),
            startTime: row.startTime.trim(),
            endTime: row.endTime.trim(),
            isActive: row.isActive,
          ),
        );
      }
      final cuisineId = state.selectedCuisineId;
      if (cuisineId == null) {
        emit(
          state.copyWith(
            status: Status.success,
            notice: 'Meal times saved',
            clearError: true,
          ),
        );
        return true;
      }
      final rows = await _loadRows(cuisineId);
      emit(
        state.copyWith(
          status: Status.success,
          rows: rows,
          notice: 'Meal times saved',
          clearError: true,
        ),
      );
      return true;
    } on Failure catch (e) {
      emit(
        state.copyWith(
          status: Status.failure,
          error: e.message,
        ),
      );
      return false;
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
      return false;
    }
  }

  /// Visible for unit tests.
  static List<MealTimeRowEdit> validateRows(List<MealTimeRowEdit> rows) =>
      _withValidation(rows);

  static List<MealTimeRowEdit> _withValidation(List<MealTimeRowEdit> rows) {
    final overlapIds = <String>{};
    for (var i = 0; i < rows.length; i++) {
      final a = rows[i];
      if (!a.isActive) continue;
      final aStart = parseMinutes(a.startTime);
      final aEnd = parseMinutes(a.endTime);
      if (aStart == null || aEnd == null || aStart >= aEnd) continue;
      for (var j = i + 1; j < rows.length; j++) {
        final b = rows[j];
        if (!b.isActive) continue;
        final bStart = parseMinutes(b.startTime);
        final bEnd = parseMinutes(b.endTime);
        if (bStart == null || bEnd == null || bStart >= bEnd) continue;
        if (aStart < bEnd && aEnd > bStart) {
          overlapIds.add(a.id);
          overlapIds.add(b.id);
        }
      }
    }

    return rows.map((row) {
      final start = parseMinutes(row.startTime);
      final end = parseMinutes(row.endTime);
      String? error;
      if (start == null || end == null) {
        error = 'Invalid time';
      } else if (start >= end) {
        error = 'Start must be before end';
      } else if (overlapIds.contains(row.id)) {
        error = 'Overlaps another window';
      }
      return row.copyWith(validationError: error, clearValidationError: error == null);
    }).toList();
  }

  static int? parseMinutes(String value) {
    final parts = value.trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }
}

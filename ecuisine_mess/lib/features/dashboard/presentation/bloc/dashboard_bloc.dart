import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';
import 'package:ecuisine_mess/features/meal_times/domain/usecases/get_meal_times.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required GetDashboardSummary getDashboardSummary,
    required GetMealTimes getMealTimes,
    this.refreshInterval = const Duration(seconds: 60),
  }) : _getDashboardSummary = getDashboardSummary,
       _getMealTimes = getMealTimes,
       super(const DashboardState()) {
    on<DashboardStarted>(_onStarted, transformer: droppable());
    on<DashboardRefreshRequested>(_onRefresh, transformer: droppable());
  }

  /// Auto-refresh period; `Duration.zero` disables the timer (tests).
  final Duration refreshInterval;

  final GetDashboardSummary _getDashboardSummary;
  final GetMealTimes _getMealTimes;
  Timer? _timer;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    _startTimer();
    emit(state.copyWith(status: Status.loading, clearError: true));
    await _load(emit);
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    // Nothing to refresh until the first load has produced data or an error.
    if (state.status == Status.initial || state.status == Status.loading) {
      return;
    }
    emit(state.copyWith(refreshing: true));
    await _load(emit);
  }

  Future<void> _load(Emitter<DashboardState> emit) async {
    try {
      final summaryFuture = _getDashboardSummary(const NoParams());
      // Timeline windows are best-effort; the summary still carries the
      // current and next window if this fails.
      final mealTimesFuture = _loadMealTimes();
      final summary = await summaryFuture;
      final mealTimes = (await mealTimesFuture).where((m) => m.isActive);
      emit(
        state.copyWith(
          status: Status.success,
          summary: summary,
          mealTimes: mealTimes.toList(),
          refreshing: false,
          clearError: true,
          clearRefreshError: true,
        ),
      );
    } on Failure catch (e) {
      emit(_failed(e.message));
    } catch (e) {
      emit(_failed(e.toString()));
    }
  }

  Future<List<MealTime>> _loadMealTimes() async {
    try {
      return await _getMealTimes(const GetMealTimesParams());
    } catch (_) {
      return state.mealTimes;
    }
  }

  DashboardState _failed(String message) {
    if (state.summary != null) {
      return state.copyWith(
        status: Status.success,
        refreshing: false,
        refreshError: message,
      );
    }
    return state.copyWith(
      status: Status.failure,
      refreshing: false,
      error: message,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    if (refreshInterval == Duration.zero) return;
    _timer = Timer.periodic(
      refreshInterval,
      (_) => add(const DashboardRefreshRequested()),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

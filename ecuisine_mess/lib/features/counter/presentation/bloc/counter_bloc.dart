import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/counter_tap_result.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/issued_bill.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';
import 'package:ecuisine_mess/features/counter/domain/usecases/get_current_meal_window.dart';
import 'package:ecuisine_mess/features/counter/domain/usecases/issue_token.dart';
import 'package:ecuisine_mess/features/counter/domain/usecases/tap_rfid.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'counter_event.dart';
part 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc({
    required GetCurrentMealWindow getCurrentMealWindow,
    required TapRfid tapRfid,
    required IssueToken issueToken,
  })  : _getCurrentMealWindow = getCurrentMealWindow,
        _tapRfid = tapRfid,
        _issueToken = issueToken,
        super(const CounterState()) {
    on<CounterStarted>(_onStarted);
    on<CounterMealWindowRequested>(_onMealWindow);
    on<CounterRfidScanned>(_onRfidScanned, transformer: droppable());
    on<CounterSupervisorOverrideGranted>(_onOverrideGranted);
    on<CounterIssueTokenRequested>(_onIssueToken, transformer: droppable());
    on<CounterCleared>(_onCleared);
    on<CounterNoticeConsumed>(_onNoticeConsumed);
  }

  final GetCurrentMealWindow _getCurrentMealWindow;
  final TapRfid _tapRfid;
  final IssueToken _issueToken;

  Future<void> _onStarted(
    CounterStarted event,
    Emitter<CounterState> emit,
  ) async {
    add(const CounterMealWindowRequested());
  }

  Future<void> _onMealWindow(
    CounterMealWindowRequested event,
    Emitter<CounterState> emit,
  ) async {
    try {
      final window = await _getCurrentMealWindow(
        GetCurrentMealWindowParams(cuisineId: event.cuisineId),
      );
      emit(state.copyWith(mealWindow: window, clearError: true));
    } on Failure {
      // Cosmetic banner; keep counter usable without a window.
    } catch (_) {}
  }

  Future<void> _onRfidScanned(
    CounterRfidScanned event,
    Emitter<CounterState> emit,
  ) async {
    final tag = event.tag.trim();
    if (tag.isEmpty) return;

    emit(
      state.copyWith(
        status: Status.loading,
        clearError: true,
        clearTap: true,
        clearOverride: true,
        clearLastIssued: true,
      ),
    );

    try {
      final result = await _tapRfid(TapRfidParams(tag));
      if (!result.success) {
        emit(
          state.copyWith(
            status: Status.failure,
            tapResult: result,
            error: result.message ?? 'Validation failed',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: Status.success,
          tapResult: result,
          clearError: true,
        ),
      );
      final cuisineId = result.member?.cuisineId;
      if (cuisineId != null && cuisineId.isNotEmpty) {
        add(CounterMealWindowRequested(cuisineId: cuisineId));
      }
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          status: Status.failure,
          error: 'Connection error: $e',
        ),
      );
    }
  }

  void _onOverrideGranted(
    CounterSupervisorOverrideGranted event,
    Emitter<CounterState> emit,
  ) {
    emit(
      state.copyWith(
        isOverride: true,
        overrideBy: event.name,
        overrideReason: event.reason,
        clearError: true,
        status: Status.success,
      ),
    );
  }

  Future<void> _onIssueToken(
    CounterIssueTokenRequested event,
    Emitter<CounterState> emit,
  ) async {
    final tap = state.tapResult;
    final memberId = tap?.member?.id;
    if (memberId == null || memberId.isEmpty) return;
    if (!(tap!.success || state.isOverride)) return;

    final mealType =
        tap.mealType ?? state.mealWindow?.mealType ?? 'LUNCH';

    emit(state.copyWith(status: Status.submitting, clearError: true));

    try {
      final bill = await _issueToken(
        IssueTokenParams(
          memberId: memberId,
          mealType: mealType,
          isOverride: state.isOverride,
          overrideBy: state.overrideBy,
          overrideReason: state.overrideReason,
        ),
      );
      emit(
        state.copyWith(
          status: Status.success,
          lastIssuedBill: bill,
          lastTokenSummary: bill.summary,
          notice: 'Token ${bill.tokenNumber} issued',
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          status: Status.failure,
          error: 'Failed to print/save bill: $e',
        ),
      );
    }
  }

  void _onCleared(
    CounterCleared event,
    Emitter<CounterState> emit,
  ) {
    emit(
      state.copyWith(
        status: Status.initial,
        clearTap: true,
        clearError: true,
        clearOverride: true,
        clearLastIssued: true,
        clearNotice: true,
      ),
    );
  }

  void _onNoticeConsumed(
    CounterNoticeConsumed event,
    Emitter<CounterState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }
}

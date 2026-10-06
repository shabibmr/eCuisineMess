import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/bills/domain/entities/bill.dart';
import 'package:ecuisine_mess/features/bills/domain/usecases/cancel_bill.dart';
import 'package:ecuisine_mess/features/bills/domain/usecases/get_bill.dart';
import 'package:ecuisine_mess/features/bills/domain/usecases/get_bills.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'bill_list_event.dart';
part 'bill_list_state.dart';

class BillListBloc extends Bloc<BillListEvent, BillListState> {
  BillListBloc({
    required GetBills getBills,
    required GetBill getBill,
    required CancelBill cancelBill,
  })  : _getBills = getBills,
        _getBill = getBill,
        _cancelBill = cancelBill,
        super(const BillListState()) {
    on<BillListStarted>(_onLoad);
    on<BillListRefreshed>(_onLoad);
    on<BillListFiltersChanged>(_onFiltersChanged, transformer: restartable());
    on<BillCancelRequested>(_onCancel, transformer: droppable());
    on<BillDetailRequested>(_onDetail, transformer: droppable());
    on<BillListNoticeConsumed>(_onNoticeConsumed);
    on<BillDetailCleared>(_onDetailCleared);
  }

  final GetBills _getBills;
  final GetBill _getBill;
  final CancelBill _cancelBill;

  Future<void> _onLoad(
    BillListEvent event,
    Emitter<BillListState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, clearError: true));
    await _fetch(emit);
  }

  Future<void> _onFiltersChanged(
    BillListFiltersChanged event,
    Emitter<BillListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: Status.loading,
        search: event.search ?? state.search,
        billDate: event.clearBillDate
            ? null
            : (event.billDate ?? state.billDate),
        mealType: event.clearMealType
            ? null
            : (event.mealType ?? state.mealType),
        billStatus: event.clearBillStatus
            ? null
            : (event.billStatus ?? state.billStatus),
        clearError: true,
        setBillDate: event.billDate != null || event.clearBillDate,
        setMealType: event.mealType != null || event.clearMealType,
        setBillStatus: event.billStatus != null || event.clearBillStatus,
      ),
    );
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<BillListState> emit) async {
    try {
      final bills = await _getBills(
        GetBillsParams(
          search: state.search.isEmpty ? null : state.search,
          billDate: state.billDate,
          mealType: state.mealType,
          status: state.billStatus,
        ),
      );
      emit(
        state.copyWith(
          status: Status.success,
          bills: bills,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onCancel(
    BillCancelRequested event,
    Emitter<BillListState> emit,
  ) async {
    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      await _cancelBill(
        CancelBillParams(
          id: event.id,
          reason: event.reason,
          cancelledBy: event.cancelledBy,
        ),
      );
      final bills = await _getBills(
        GetBillsParams(
          search: state.search.isEmpty ? null : state.search,
          billDate: state.billDate,
          mealType: state.mealType,
          status: state.billStatus,
        ),
      );
      emit(
        state.copyWith(
          status: Status.success,
          bills: bills,
          notice: 'Bill cancelled',
          clearError: true,
          clearSelected: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onDetail(
    BillDetailRequested event,
    Emitter<BillListState> emit,
  ) async {
    emit(state.copyWith(detailStatus: Status.loading, clearDetailError: true));
    try {
      final bill = await _getBill(GetBillParams(event.id));
      emit(
        state.copyWith(
          detailStatus: Status.success,
          selectedBill: bill,
          clearDetailError: true,
        ),
      );
    } on Failure catch (e) {
      emit(
        state.copyWith(
          detailStatus: Status.failure,
          detailError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          detailStatus: Status.failure,
          detailError: e.toString(),
        ),
      );
    }
  }

  void _onNoticeConsumed(
    BillListNoticeConsumed event,
    Emitter<BillListState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }

  void _onDetailCleared(
    BillDetailCleared event,
    Emitter<BillListState> emit,
  ) {
    emit(state.copyWith(clearSelected: true));
  }
}

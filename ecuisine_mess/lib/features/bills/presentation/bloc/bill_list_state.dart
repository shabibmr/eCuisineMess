part of 'bill_list_bloc.dart';

final class BillListState extends Equatable {
  const BillListState({
    this.status = Status.initial,
    this.bills = const [],
    this.search = '',
    this.billDate,
    this.mealType,
    this.billStatus,
    this.error,
    this.notice,
    this.selectedBill,
    this.detailStatus = Status.initial,
    this.detailError,
  });

  final Status status;
  final List<Bill> bills;
  final String search;
  final String? billDate;
  final String? mealType;
  final String? billStatus;
  final String? error;
  final String? notice;
  final Bill? selectedBill;
  final Status detailStatus;
  final String? detailError;

  BillListState copyWith({
    Status? status,
    List<Bill>? bills,
    String? search,
    String? billDate,
    String? mealType,
    String? billStatus,
    String? error,
    String? notice,
    Bill? selectedBill,
    Status? detailStatus,
    String? detailError,
    bool clearError = false,
    bool clearNotice = false,
    bool clearSelected = false,
    bool clearDetailError = false,
    bool setBillDate = false,
    bool setMealType = false,
    bool setBillStatus = false,
  }) {
    return BillListState(
      status: status ?? this.status,
      bills: bills ?? this.bills,
      search: search ?? this.search,
      billDate: setBillDate ? billDate : (billDate ?? this.billDate),
      mealType: setMealType ? mealType : (mealType ?? this.mealType),
      billStatus:
          setBillStatus ? billStatus : (billStatus ?? this.billStatus),
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
      selectedBill:
          clearSelected ? null : (selectedBill ?? this.selectedBill),
      detailStatus: clearSelected
          ? Status.initial
          : (detailStatus ?? this.detailStatus),
      detailError: clearSelected || clearDetailError
          ? null
          : (detailError ?? this.detailError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        bills,
        search,
        billDate,
        mealType,
        billStatus,
        error,
        notice,
        selectedBill,
        detailStatus,
        detailError,
      ];
}

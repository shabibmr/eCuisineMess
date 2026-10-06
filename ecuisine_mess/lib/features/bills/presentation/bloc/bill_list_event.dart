part of 'bill_list_bloc.dart';

sealed class BillListEvent extends Equatable {
  const BillListEvent();

  @override
  List<Object?> get props => [];
}

final class BillListStarted extends BillListEvent {
  const BillListStarted();
}

final class BillListRefreshed extends BillListEvent {
  const BillListRefreshed();
}

final class BillListFiltersChanged extends BillListEvent {
  const BillListFiltersChanged({
    this.search,
    this.billDate,
    this.mealType,
    this.billStatus,
    this.clearBillDate = false,
    this.clearMealType = false,
    this.clearBillStatus = false,
  });

  final String? search;
  final String? billDate;
  final String? mealType;
  final String? billStatus;
  final bool clearBillDate;
  final bool clearMealType;
  final bool clearBillStatus;

  @override
  List<Object?> get props => [
        search,
        billDate,
        mealType,
        billStatus,
        clearBillDate,
        clearMealType,
        clearBillStatus,
      ];
}

final class BillCancelRequested extends BillListEvent {
  const BillCancelRequested({
    required this.id,
    required this.reason,
    required this.cancelledBy,
  });

  final String id;
  final String reason;
  final String cancelledBy;

  @override
  List<Object?> get props => [id, reason, cancelledBy];
}

final class BillDetailRequested extends BillListEvent {
  const BillDetailRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class BillDetailCleared extends BillListEvent {
  const BillDetailCleared();
}

final class BillListNoticeConsumed extends BillListEvent {
  const BillListNoticeConsumed();
}

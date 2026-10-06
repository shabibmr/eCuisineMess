part of 'counter_bloc.dart';

final class CounterState extends Equatable {
  const CounterState({
    this.status = Status.initial,
    this.mealWindow,
    this.tapResult,
    this.isOverride = false,
    this.overrideBy,
    this.overrideReason,
    this.lastIssuedBill,
    this.lastTokenSummary,
    this.error,
    this.notice,
  });

  final Status status;
  final MealWindow? mealWindow;
  final CounterTapResult? tapResult;
  final bool isOverride;
  final String? overrideBy;
  final String? overrideReason;
  final IssuedBill? lastIssuedBill;
  final String? lastTokenSummary;
  final String? error;
  final String? notice;

  bool get showInvoice =>
      tapResult?.member != null && (tapResult!.success || isOverride);

  bool get canIssue => showInvoice && status != Status.submitting;

  CounterState copyWith({
    Status? status,
    MealWindow? mealWindow,
    CounterTapResult? tapResult,
    bool? isOverride,
    String? overrideBy,
    String? overrideReason,
    IssuedBill? lastIssuedBill,
    String? lastTokenSummary,
    String? error,
    String? notice,
    bool clearError = false,
    bool clearNotice = false,
    bool clearTap = false,
    bool clearOverride = false,
    bool clearLastIssued = false,
  }) {
    return CounterState(
      status: status ?? this.status,
      mealWindow: mealWindow ?? this.mealWindow,
      tapResult: clearTap ? null : (tapResult ?? this.tapResult),
      isOverride: clearOverride ? false : (isOverride ?? this.isOverride),
      overrideBy: clearOverride ? null : (overrideBy ?? this.overrideBy),
      overrideReason:
          clearOverride ? null : (overrideReason ?? this.overrideReason),
      lastIssuedBill:
          clearLastIssued ? null : (lastIssuedBill ?? this.lastIssuedBill),
      lastTokenSummary: lastTokenSummary ?? this.lastTokenSummary,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [
        status,
        mealWindow,
        tapResult,
        isOverride,
        overrideBy,
        overrideReason,
        lastIssuedBill,
        lastTokenSummary,
        error,
        notice,
      ];
}

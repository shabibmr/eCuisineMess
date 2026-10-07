part of 'dashboard_bloc.dart';

final class DashboardState extends Equatable {
  const DashboardState({
    this.status = Status.initial,
    this.summary,
    this.mealTimes = const [],
    this.error,
    this.refreshError,
    this.refreshing = false,
  });

  final Status status;
  final DashboardSummary? summary;

  /// Active meal windows across all cuisines, for the timeline.
  final List<MealTime> mealTimes;

  /// Set when there is no data to show (`Status.failure`).
  final String? error;

  /// Set when a refresh failed but the last data is still shown.
  final String? refreshError;

  final bool refreshing;

  DashboardState copyWith({
    Status? status,
    DashboardSummary? summary,
    List<MealTime>? mealTimes,
    String? error,
    bool clearError = false,
    String? refreshError,
    bool clearRefreshError = false,
    bool? refreshing,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      mealTimes: mealTimes ?? this.mealTimes,
      error: clearError ? null : (error ?? this.error),
      refreshError: clearRefreshError
          ? null
          : (refreshError ?? this.refreshError),
      refreshing: refreshing ?? this.refreshing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    summary,
    mealTimes,
    error,
    refreshError,
    refreshing,
  ];
}

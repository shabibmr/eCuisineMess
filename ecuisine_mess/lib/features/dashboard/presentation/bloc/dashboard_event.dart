part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// First load; shows the full-page loading state and starts auto-refresh.
final class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

/// Manual or timer-driven reload. Keeps the last data on screen.
final class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

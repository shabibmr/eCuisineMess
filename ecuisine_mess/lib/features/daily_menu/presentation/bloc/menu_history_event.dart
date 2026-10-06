part of 'menu_history_bloc.dart';

sealed class MenuHistoryEvent extends Equatable {
  const MenuHistoryEvent();

  @override
  List<Object?> get props => [];
}

class MenuHistoryStarted extends MenuHistoryEvent {
  const MenuHistoryStarted({
    this.fromDate,
    this.toDate,
    this.cuisineId,
  });

  final String? fromDate;
  final String? toDate;
  final String? cuisineId;

  @override
  List<Object?> get props => [fromDate, toDate, cuisineId];
}

class MenuHistoryDateRangeChanged extends MenuHistoryEvent {
  const MenuHistoryDateRangeChanged({
    required this.fromDate,
    required this.toDate,
  });

  final String fromDate;
  final String toDate;

  @override
  List<Object?> get props => [fromDate, toDate];
}

class MenuHistoryCuisineFiltered extends MenuHistoryEvent {
  const MenuHistoryCuisineFiltered(this.cuisineId);

  final String? cuisineId;

  @override
  List<Object?> get props => [cuisineId];
}

class MenuHistorySearchChanged extends MenuHistoryEvent {
  const MenuHistorySearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class MenuHistoryRefreshRequested extends MenuHistoryEvent {
  const MenuHistoryRefreshRequested();
}

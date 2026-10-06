part of 'menu_history_bloc.dart';

class MenuHistoryState extends Equatable {
  const MenuHistoryState({
    this.status = Status.initial,
    this.cuisines = const [],
    this.records = const [],
    this.fromDate = '',
    this.toDate = '',
    this.selectedCuisineId,
    this.searchQuery = '',
    this.error,
  });

  final Status status;
  final List<CuisineOption> cuisines;
  final List<MenuHistoryRecord> records;
  final String fromDate;
  final String toDate;
  final String? selectedCuisineId;
  final String searchQuery;
  final String? error;

  List<MenuHistoryRecord> get filteredRecords {
    if (searchQuery.trim().isEmpty) return records;
    final q = searchQuery.trim().toLowerCase();
    return records.where((r) {
      return r.cuisineName.toLowerCase().contains(q) ||
          r.date.contains(q);
    }).toList();
  }

  MenuHistoryState copyWith({
    Status? status,
    List<CuisineOption>? cuisines,
    List<MenuHistoryRecord>? records,
    String? fromDate,
    String? toDate,
    Object? selectedCuisineId = _sentinel,
    String? searchQuery,
    Object? error = _sentinel,
  }) {
    return MenuHistoryState(
      status: status ?? this.status,
      cuisines: cuisines ?? this.cuisines,
      records: records ?? this.records,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      selectedCuisineId: identical(selectedCuisineId, _sentinel)
          ? this.selectedCuisineId
          : selectedCuisineId as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();

  @override
  List<Object?> get props => [
        status,
        cuisines,
        records,
        fromDate,
        toDate,
        selectedCuisineId,
        searchQuery,
        error,
      ];
}

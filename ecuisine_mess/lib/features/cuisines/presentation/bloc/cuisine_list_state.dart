part of 'cuisine_list_bloc.dart';

class CuisineListState extends Equatable {
  const CuisineListState({
    this.status = Status.initial,
    this.cuisines = const [],
    this.searchQuery = '',
    this.showInactive = true,
    this.error,
    this.notice,
  });

  final Status status;
  final List<Cuisine> cuisines;
  final String searchQuery;
  final bool showInactive;
  final String? error;
  final String? notice;

  List<Cuisine> get filteredCuisines {
    final query = searchQuery.trim().toLowerCase();
    return cuisines.where((c) {
      if (!showInactive && !c.isActive) return false;
      if (query.isEmpty) return true;
      final name = c.cuisineName.toLowerCase();
      final desc = c.description?.toLowerCase() ?? '';
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  CuisineListState copyWith({
    Status? status,
    List<Cuisine>? cuisines,
    String? searchQuery,
    bool? showInactive,
    String? error,
    bool clearError = false,
    String? notice,
    bool clearNotice = false,
  }) {
    return CuisineListState(
      status: status ?? this.status,
      cuisines: cuisines ?? this.cuisines,
      searchQuery: searchQuery ?? this.searchQuery,
      showInactive: showInactive ?? this.showInactive,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [
        status,
        cuisines,
        searchQuery,
        showInactive,
        error,
        notice,
      ];
}

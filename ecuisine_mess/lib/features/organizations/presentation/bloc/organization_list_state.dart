part of 'organization_list_bloc.dart';

final class OrganizationListState extends Equatable {
  const OrganizationListState({
    this.status = Status.initial,
    this.organizations = const [],
    this.error,
    this.notice,
    this.searchQuery,
  });

  final Status status;
  final List<Organization> organizations;
  final String? error;
  final String? notice;
  final String? searchQuery;

  OrganizationListState copyWith({
    Status? status,
    List<Organization>? organizations,
    String? error,
    String? notice,
    String? searchQuery,
    bool clearError = false,
    bool clearNotice = false,
  }) {
    return OrganizationListState(
      status: status ?? this.status,
      organizations: organizations ?? this.organizations,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        status,
        organizations,
        error,
        notice,
        searchQuery,
      ];
}

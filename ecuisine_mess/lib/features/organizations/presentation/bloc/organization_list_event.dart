part of 'organization_list_bloc.dart';

sealed class OrganizationListEvent extends Equatable {
  const OrganizationListEvent();

  @override
  List<Object?> get props => [];
}

final class OrganizationListStarted extends OrganizationListEvent {
  const OrganizationListStarted({this.search});

  final String? search;

  @override
  List<Object?> get props => [search];
}

final class OrganizationListRefreshed extends OrganizationListEvent {
  const OrganizationListRefreshed();
}

final class OrganizationSaveRequested extends OrganizationListEvent {
  const OrganizationSaveRequested(this.params);

  final SaveOrganizationParams params;

  @override
  List<Object?> get props => [params];
}

final class OrganizationDeleteRequested extends OrganizationListEvent {
  const OrganizationDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class OrganizationListNoticeConsumed extends OrganizationListEvent {
  const OrganizationListNoticeConsumed();
}

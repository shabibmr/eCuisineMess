part of 'member_list_bloc.dart';

final class MemberListState extends Equatable {
  const MemberListState({
    this.status = Status.initial,
    this.members = const [],
    this.cuisines = const [],
    this.search = '',
    this.statusFilter,
    this.error,
    this.notice,
    this.rfidAvailability,
  });

  final Status status;
  final List<Member> members;
  final List<CuisineOption> cuisines;
  final String search;
  final String? statusFilter;
  final String? error;
  final String? notice;
  final RfidAvailability? rfidAvailability;

  List<CuisineOption> get activeCuisines =>
      cuisines.where((c) => c.isActive).toList();

  MemberListState copyWith({
    Status? status,
    List<Member>? members,
    List<CuisineOption>? cuisines,
    String? search,
    String? statusFilter,
    String? error,
    String? notice,
    RfidAvailability? rfidAvailability,
    bool clearError = false,
    bool clearNotice = false,
    bool clearStatusFilter = false,
    bool clearRfidAvailability = false,
  }) {
    return MemberListState(
      status: status ?? this.status,
      members: members ?? this.members,
      cuisines: cuisines ?? this.cuisines,
      search: search ?? this.search,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
      rfidAvailability: clearRfidAvailability
          ? null
          : (rfidAvailability ?? this.rfidAvailability),
    );
  }

  @override
  List<Object?> get props => [
        status,
        members,
        cuisines,
        search,
        statusFilter,
        error,
        notice,
        rfidAvailability,
      ];
}

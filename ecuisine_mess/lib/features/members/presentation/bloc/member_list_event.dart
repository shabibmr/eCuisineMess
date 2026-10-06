part of 'member_list_bloc.dart';

sealed class MemberListEvent extends Equatable {
  const MemberListEvent();

  @override
  List<Object?> get props => [];
}

final class MemberListStarted extends MemberListEvent {
  const MemberListStarted();
}

final class MemberListRefreshed extends MemberListEvent {
  const MemberListRefreshed();
}

final class MemberListSearchChanged extends MemberListEvent {
  const MemberListSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

final class MemberListStatusFilterChanged extends MemberListEvent {
  const MemberListStatusFilterChanged(this.status);

  final String? status;

  @override
  List<Object?> get props => [status];
}

final class MemberSaveRequested extends MemberListEvent {
  const MemberSaveRequested(this.params);

  final SaveMemberParams params;

  @override
  List<Object?> get props => [params];
}

final class MemberRfidCheckRequested extends MemberListEvent {
  const MemberRfidCheckRequested({
    required this.tag,
    this.excludeMemberId,
  });

  final String tag;
  final String? excludeMemberId;

  @override
  List<Object?> get props => [tag, excludeMemberId];
}

final class MemberListNoticeConsumed extends MemberListEvent {
  const MemberListNoticeConsumed();
}

final class MemberRfidCheckCleared extends MemberListEvent {
  const MemberRfidCheckCleared();
}

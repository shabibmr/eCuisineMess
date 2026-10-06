import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member.dart';
import 'package:ecuisine_mess/features/members/domain/entities/rfid_availability.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/check_rfid_available.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/get_cuisine_options.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/get_members.dart';
import 'package:ecuisine_mess/features/members/domain/usecases/save_member.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'member_list_event.dart';
part 'member_list_state.dart';

class MemberListBloc extends Bloc<MemberListEvent, MemberListState> {
  MemberListBloc({
    required GetMembers getMembers,
    required GetCuisineOptions getCuisineOptions,
    required SaveMember saveMember,
    required CheckRfidAvailable checkRfidAvailable,
  })  : _getMembers = getMembers,
        _getCuisineOptions = getCuisineOptions,
        _saveMember = saveMember,
        _checkRfidAvailable = checkRfidAvailable,
        super(const MemberListState()) {
    on<MemberListStarted>(_onStarted);
    on<MemberListRefreshed>(_onRefresh);
    on<MemberListSearchChanged>(_onSearchChanged, transformer: restartable());
    on<MemberListStatusFilterChanged>(
      _onStatusFilterChanged,
      transformer: restartable(),
    );
    on<MemberSaveRequested>(_onSave, transformer: droppable());
    on<MemberRfidCheckRequested>(_onRfidCheck, transformer: droppable());
    on<MemberListNoticeConsumed>(_onNoticeConsumed);
    on<MemberRfidCheckCleared>(_onRfidCheckCleared);
  }

  final GetMembers _getMembers;
  final GetCuisineOptions _getCuisineOptions;
  final SaveMember _saveMember;
  final CheckRfidAvailable _checkRfidAvailable;

  Future<void> _onStarted(
    MemberListStarted event,
    Emitter<MemberListState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, clearError: true));
    try {
      final results = await Future.wait([
        _getMembers(const GetMembersParams()),
        _getCuisineOptions(const GetCuisineOptionsParams()),
      ]);
      emit(
        state.copyWith(
          status: Status.success,
          members: results[0] as List<Member>,
          cuisines: results[1] as List<CuisineOption>,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onRefresh(
    MemberListRefreshed event,
    Emitter<MemberListState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, clearError: true));
    await _fetchMembers(emit);
  }

  Future<void> _onSearchChanged(
    MemberListSearchChanged event,
    Emitter<MemberListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: Status.loading,
        search: event.search,
        clearError: true,
      ),
    );
    await _fetchMembers(emit);
  }

  Future<void> _onStatusFilterChanged(
    MemberListStatusFilterChanged event,
    Emitter<MemberListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: Status.loading,
        statusFilter: event.status,
        clearStatusFilter: event.status == null,
        clearError: true,
      ),
    );
    await _fetchMembers(emit);
  }

  Future<void> _fetchMembers(Emitter<MemberListState> emit) async {
    try {
      final members = await _getMembers(
        GetMembersParams(
          search: state.search.isEmpty ? null : state.search,
          status: state.statusFilter,
        ),
      );
      emit(
        state.copyWith(
          status: Status.success,
          members: members,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onSave(
    MemberSaveRequested event,
    Emitter<MemberListState> emit,
  ) async {
    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      final availability = await _checkRfidAvailable(
        CheckRfidAvailableParams(
          tag: event.params.rfidTag,
          excludeMemberId: event.params.id,
        ),
      );
      if (!availability.available) {
        final who = availability.conflictingMemberName ?? 'another member';
        emit(
          state.copyWith(
            status: Status.failure,
            error: 'RFID tag already used by $who',
            rfidAvailability: availability,
          ),
        );
        return;
      }

      await _saveMember(event.params);
      final members = await _getMembers(
        GetMembersParams(
          search: state.search.isEmpty ? null : state.search,
          status: state.statusFilter,
        ),
      );
      emit(
        state.copyWith(
          status: Status.success,
          members: members,
          notice: event.params.id == null
              ? 'Member created'
              : 'Member updated',
          clearError: true,
          clearRfidAvailability: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onRfidCheck(
    MemberRfidCheckRequested event,
    Emitter<MemberListState> emit,
  ) async {
    final tag = event.tag.trim();
    if (tag.isEmpty) {
      emit(
        state.copyWith(
          rfidAvailability: null,
          clearRfidAvailability: true,
        ),
      );
      return;
    }
    try {
      final availability = await _checkRfidAvailable(
        CheckRfidAvailableParams(
          tag: tag,
          excludeMemberId: event.excludeMemberId,
        ),
      );
      emit(state.copyWith(rfidAvailability: availability));
    } on Failure catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onNoticeConsumed(
    MemberListNoticeConsumed event,
    Emitter<MemberListState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }

  void _onRfidCheckCleared(
    MemberRfidCheckCleared event,
    Emitter<MemberListState> emit,
  ) {
    emit(state.copyWith(clearRfidAvailability: true));
  }
}

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/organizations/domain/entities/organization.dart';
import 'package:ecuisine_mess/features/organizations/domain/usecases/delete_organization.dart';
import 'package:ecuisine_mess/features/organizations/domain/usecases/get_organizations.dart';
import 'package:ecuisine_mess/features/organizations/domain/usecases/save_organization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'organization_list_event.dart';
part 'organization_list_state.dart';

class OrganizationListBloc
    extends Bloc<OrganizationListEvent, OrganizationListState> {
  OrganizationListBloc({
    required GetOrganizations getOrganizations,
    required SaveOrganization saveOrganization,
    required DeleteOrganization deleteOrganization,
  })  : _getOrganizations = getOrganizations,
        _saveOrganization = saveOrganization,
        _deleteOrganization = deleteOrganization,
        super(const OrganizationListState()) {
    on<OrganizationListStarted>(_onLoad);
    on<OrganizationListRefreshed>(_onRefresh);
    on<OrganizationSaveRequested>(_onSave, transformer: droppable());
    on<OrganizationDeleteRequested>(_onDelete, transformer: droppable());
    on<OrganizationListNoticeConsumed>(_onNoticeConsumed);
  }

  final GetOrganizations _getOrganizations;
  final SaveOrganization _saveOrganization;
  final DeleteOrganization _deleteOrganization;

  Future<void> _onLoad(
    OrganizationListStarted event,
    Emitter<OrganizationListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: Status.loading,
        searchQuery: event.search,
        clearError: true,
      ),
    );
    try {
      final organizations = await _getOrganizations(
        GetOrganizationsParams(
          search: event.search,
          includeInactive: true,
        ),
      );
      emit(
        state.copyWith(
          status: Status.success,
          organizations: organizations,
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
    OrganizationListRefreshed event,
    Emitter<OrganizationListState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, clearError: true));
    try {
      final organizations = await _getOrganizations(
        GetOrganizationsParams(
          search: state.searchQuery,
          includeInactive: true,
        ),
      );
      emit(
        state.copyWith(
          status: Status.success,
          organizations: organizations,
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
    OrganizationSaveRequested event,
    Emitter<OrganizationListState> emit,
  ) async {
    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      await _saveOrganization(event.params);
      final organizations = await _getOrganizations(
        GetOrganizationsParams(
          search: state.searchQuery,
          includeInactive: true,
        ),
      );
      emit(
        state.copyWith(
          status: Status.success,
          organizations: organizations,
          notice: event.params.id == null
              ? 'Organization created'
              : 'Organization updated',
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onDelete(
    OrganizationDeleteRequested event,
    Emitter<OrganizationListState> emit,
  ) async {
    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      await _deleteOrganization(DeleteOrganizationParams(id: event.id));
      final organizations = await _getOrganizations(
        GetOrganizationsParams(
          search: state.searchQuery,
          includeInactive: true,
        ),
      );
      emit(
        state.copyWith(
          status: Status.success,
          organizations: organizations,
          notice: 'Organization deleted',
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  void _onNoticeConsumed(
    OrganizationListNoticeConsumed event,
    Emitter<OrganizationListState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }
}

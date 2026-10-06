import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/delete_cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/get_cuisines.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cuisine_list_event.dart';
part 'cuisine_list_state.dart';

class CuisineListBloc extends Bloc<CuisineListEvent, CuisineListState> {
  CuisineListBloc({
    required GetCuisines getCuisines,
    required DeleteCuisine deleteCuisine,
  })  : _getCuisines = getCuisines,
        _deleteCuisine = deleteCuisine,
        super(const CuisineListState()) {
    on<CuisineListStarted>(_onLoad);
    on<CuisineListRefreshed>(_onLoad);
    on<CuisineSearchChanged>(_onSearchChanged, transformer: restartable());
    on<CuisineFilterInactiveToggled>(_onFilterInactiveToggled);
    on<CuisineDeleteRequested>(_onDelete, transformer: droppable());
    on<CuisineNoticeConsumed>(_onNoticeConsumed);
  }

  final GetCuisines _getCuisines;
  final DeleteCuisine _deleteCuisine;

  Future<void> _onLoad(
    CuisineListEvent event,
    Emitter<CuisineListState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, clearError: true));
    try {
      final list = await _getCuisines(
        const GetCuisinesParams(includeInactive: true),
      );
      emit(
        state.copyWith(
          status: Status.success,
          cuisines: list,
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  void _onSearchChanged(
    CuisineSearchChanged event,
    Emitter<CuisineListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onFilterInactiveToggled(
    CuisineFilterInactiveToggled event,
    Emitter<CuisineListState> emit,
  ) {
    emit(state.copyWith(showInactive: event.showInactive));
  }

  Future<void> _onDelete(
    CuisineDeleteRequested event,
    Emitter<CuisineListState> emit,
  ) async {
    try {
      final res = await _deleteCuisine(event.id);
      final list = await _getCuisines(
        const GetCuisinesParams(includeInactive: true),
      );
      emit(
        state.copyWith(
          cuisines: list,
          notice: res.wasDeactivated
              ? 'Cuisine has active members or history. Marked as inactive.'
              : 'Cuisine deleted successfully.',
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(state.copyWith(error: e.message));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onNoticeConsumed(
    CuisineNoticeConsumed event,
    Emitter<CuisineListState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }
}

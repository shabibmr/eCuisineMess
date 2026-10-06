import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping_input.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/get_cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/get_cuisines.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/save_cuisine.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/get_items.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'cuisine_editor_event.dart';
part 'cuisine_editor_state.dart';

class CuisineEditorBloc extends Bloc<CuisineEditorEvent, CuisineEditorState> {
  CuisineEditorBloc({
    required GetCuisine getCuisine,
    required GetCuisines getCuisines,
    required GetItems getItems,
    required SaveCuisine saveCuisine,
  })  : _getCuisine = getCuisine,
        _getCuisines = getCuisines,
        _getItems = getItems,
        _saveCuisine = saveCuisine,
        super(const CuisineEditorState()) {
    on<CuisineEditorStarted>(_onStarted);
    on<CuisineEditorNameChanged>(_onNameChanged);
    on<CuisineEditorDescriptionChanged>(_onDescriptionChanged);
    on<CuisineEditorActiveToggled>(_onActiveToggled);
    on<CuisineEditorItemsMapped>(_onItemsMapped);
    on<CuisineEditorItemsRemoved>(_onItemsRemoved);
    on<CuisineEditorItemQtyChanged>(_onItemQtyChanged);
    on<CuisineEditorCopyMappingRequested>(_onCopyMappingRequested);
    on<CuisineEditorSubmitted>(_onSubmitted, transformer: droppable());
    on<CuisineEditorDismissConflict>(_onDismissConflict);
  }

  final GetCuisine _getCuisine;
  final GetCuisines _getCuisines;
  final GetItems _getItems;
  final SaveCuisine _saveCuisine;

  Future<void> _onStarted(
    CuisineEditorStarted event,
    Emitter<CuisineEditorState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, clearError: true));
    try {
      final availableItemsFuture = _getItems(
        const GetItemsParams(includeInactive: false),
      );
      final allCuisinesFuture = _getCuisines(
        const GetCuisinesParams(includeInactive: true),
      );

      final availableItems = await availableItemsFuture;
      final allCuisines = await allCuisinesFuture;

      if (event.cuisineId != null && event.cuisineId!.isNotEmpty) {
        final cuisine = await _getCuisine(event.cuisineId!);
        emit(
          state.copyWith(
            status: Status.success,
            cuisineId: cuisine.id,
            name: cuisine.cuisineName,
            description: cuisine.description ?? '',
            isActive: cuisine.isActive,
            mappedItems: cuisine.items,
            availableItems: availableItems,
            otherCuisines: allCuisines.where((c) => c.id != cuisine.id).toList(),
            clearError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: Status.success,
            cuisineId: null,
            name: '',
            description: '',
            isActive: true,
            mappedItems: const [],
            availableItems: availableItems,
            otherCuisines: allCuisines,
            clearError: true,
          ),
        );
      }
    } on Failure catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.message));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  void _onNameChanged(
    CuisineEditorNameChanged event,
    Emitter<CuisineEditorState> emit,
  ) {
    emit(state.copyWith(name: event.name));
  }

  void _onDescriptionChanged(
    CuisineEditorDescriptionChanged event,
    Emitter<CuisineEditorState> emit,
  ) {
    emit(state.copyWith(description: event.description));
  }

  void _onActiveToggled(
    CuisineEditorActiveToggled event,
    Emitter<CuisineEditorState> emit,
  ) {
    emit(state.copyWith(isActive: event.isActive));
  }

  void _onItemsMapped(
    CuisineEditorItemsMapped event,
    Emitter<CuisineEditorState> emit,
  ) {
    final current = List<CuisineItemMapping>.from(state.mappedItems);
    final currentIds = current.map((m) => m.itemId).toSet();

    for (final it in event.newItems) {
      if (!currentIds.contains(it.itemId)) {
        current.add(it);
        currentIds.add(it.itemId);
      }
    }
    emit(state.copyWith(mappedItems: current));
  }

  void _onItemsRemoved(
    CuisineEditorItemsRemoved event,
    Emitter<CuisineEditorState> emit,
  ) {
    final toRemove = event.itemIds.toSet();
    final updated = state.mappedItems
        .where((m) => !toRemove.contains(m.itemId))
        .toList();
    emit(state.copyWith(mappedItems: updated));
  }

  void _onItemQtyChanged(
    CuisineEditorItemQtyChanged event,
    Emitter<CuisineEditorState> emit,
  ) {
    final updated = state.mappedItems.map((m) {
      if (m.itemId == event.itemId) {
        return m.copyWith(defaultQty: event.qty);
      }
      return m;
    }).toList();
    emit(state.copyWith(mappedItems: updated));
  }

  Future<void> _onCopyMappingRequested(
    CuisineEditorCopyMappingRequested event,
    Emitter<CuisineEditorState> emit,
  ) async {
    try {
      final source = state.otherCuisines.firstWhere(
        (c) => c.id == event.sourceCuisineId,
      );
      final current = List<CuisineItemMapping>.from(state.mappedItems);
      final currentIds = current.map((m) => m.itemId).toSet();

      int addedCount = 0;
      for (final srcItem in source.items) {
        if (!currentIds.contains(srcItem.itemId)) {
          current.add(srcItem);
          currentIds.add(srcItem.itemId);
          addedCount++;
        }
      }

      emit(
        state.copyWith(
          mappedItems: current,
          savedMessage: 'Copied $addedCount item(s) from "${source.cuisineName}".',
        ),
      );
    } catch (_) {
      // Fallback: fetch via GetCuisine
      try {
        final source = await _getCuisine(event.sourceCuisineId);
        final current = List<CuisineItemMapping>.from(state.mappedItems);
        final currentIds = current.map((m) => m.itemId).toSet();

        int addedCount = 0;
        for (final srcItem in source.items) {
          if (!currentIds.contains(srcItem.itemId)) {
            current.add(srcItem);
            currentIds.add(srcItem.itemId);
            addedCount++;
          }
        }
        emit(
          state.copyWith(
            mappedItems: current,
            savedMessage: 'Copied $addedCount item(s) from "${source.cuisineName}".',
          ),
        );
      } on Failure catch (e) {
        emit(state.copyWith(error: e.message));
      }
    }
  }

  Future<void> _onSubmitted(
    CuisineEditorSubmitted event,
    Emitter<CuisineEditorState> emit,
  ) async {
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(error: 'Cuisine name is required.'));
      return;
    }

    emit(state.copyWith(isSaving: true, clearError: true, clearConflict: true));
    try {
      final itemsInput = state.mappedItems.asMap().entries.map((entry) {
        return CuisineItemMappingInput(
          itemId: entry.value.itemId,
          defaultQty: entry.value.defaultQty,
          sortOrder: entry.key,
        );
      }).toList();

      await _saveCuisine(
        SaveCuisineParams(
          id: state.cuisineId,
          cuisineName: name,
          description: state.description.trim().isEmpty ? null : state.description.trim(),
          isActive: state.isActive,
          items: itemsInput,
        ),
      );

      emit(
        state.copyWith(
          isSaving: false,
          saved: true,
          savedMessage: state.isNew
              ? 'Cuisine created successfully.'
              : 'Cuisine updated successfully.',
        ),
      );
    } on ConflictFailure catch (e) {
      if (e.code == 'UNMAP_BLOCKED') {
        emit(
          state.copyWith(
            isSaving: false,
            unmapConflictMessage: e.message,
            unmapConflictDetails: e.context,
          ),
        );
      } else {
        emit(state.copyWith(isSaving: false, error: e.message));
      }
    } on Failure catch (e) {
      emit(state.copyWith(isSaving: false, error: e.message));
    } catch (e) {
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  void _onDismissConflict(
    CuisineEditorDismissConflict event,
    Emitter<CuisineEditorState> emit,
  ) {
    emit(state.copyWith(clearConflict: true));
  }
}

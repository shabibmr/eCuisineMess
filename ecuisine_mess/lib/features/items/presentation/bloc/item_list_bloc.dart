import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/item_categories/domain/entities/item_category.dart';
import 'package:ecuisine_mess/features/item_categories/domain/usecases/get_item_categories.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item.dart';
import 'package:ecuisine_mess/features/items/domain/entities/uom.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/delete_item.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/get_items.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/get_uoms.dart';
import 'package:ecuisine_mess/features/items/domain/usecases/save_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'item_list_event.dart';
part 'item_list_state.dart';

class ItemListBloc extends Bloc<ItemListEvent, ItemListState> {
  ItemListBloc({
    required GetItems getItems,
    required GetUoms getUoms,
    required GetItemCategories getItemCategories,
    required SaveItem saveItem,
    required DeleteItem deleteItem,
  })  : _getItems = getItems,
        _getUoms = getUoms,
        _getItemCategories = getItemCategories,
        _saveItem = saveItem,
        _deleteItem = deleteItem,
        super(const ItemListState()) {
    on<ItemListStarted>(_onLoad);
    on<ItemListRefreshed>(_onLoad);
    on<ItemSaveRequested>(_onSave, transformer: droppable());
    on<ItemDeleteRequested>(_onDelete, transformer: droppable());
    on<ItemListNoticeConsumed>(_onNoticeConsumed);
  }

  final GetItems _getItems;
  final GetUoms _getUoms;
  final GetItemCategories _getItemCategories;
  final SaveItem _saveItem;
  final DeleteItem _deleteItem;

  Future<void> _onLoad(
    ItemListEvent event,
    Emitter<ItemListState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, clearError: true));
    try {
      final results = await Future.wait([
        _getItems(const GetItemsParams(includeInactive: true)),
        _getItemCategories(
          const GetItemCategoriesParams(includeInactive: true),
        ),
        _getUoms(const GetUomsParams()),
      ]);
      emit(
        state.copyWith(
          status: Status.success,
          items: results[0] as List<Item>,
          categories: results[1] as List<ItemCategory>,
          uoms: results[2] as List<Uom>,
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
    ItemSaveRequested event,
    Emitter<ItemListState> emit,
  ) async {
    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      await _saveItem(event.params);
      final items = await _getItems(
        const GetItemsParams(includeInactive: true),
      );
      emit(
        state.copyWith(
          status: Status.success,
          items: items,
          notice: event.params.id == null ? 'Item created' : 'Item updated',
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
    ItemDeleteRequested event,
    Emitter<ItemListState> emit,
  ) async {
    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      final result = await _deleteItem(DeleteItemParams(event.id));
      final items = await _getItems(
        const GetItemsParams(includeInactive: true),
      );
      emit(
        state.copyWith(
          status: Status.success,
          items: items,
          notice: result.message,
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
    ItemListNoticeConsumed event,
    Emitter<ItemListState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }
}

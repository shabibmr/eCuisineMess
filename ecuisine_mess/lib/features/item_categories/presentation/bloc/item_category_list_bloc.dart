import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/item_categories/domain/entities/item_category.dart';
import 'package:ecuisine_mess/features/item_categories/domain/usecases/get_item_categories.dart';
import 'package:ecuisine_mess/features/item_categories/domain/usecases/save_item_category.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'item_category_list_event.dart';
part 'item_category_list_state.dart';

class ItemCategoryListBloc
    extends Bloc<ItemCategoryListEvent, ItemCategoryListState> {
  ItemCategoryListBloc({
    required GetItemCategories getItemCategories,
    required SaveItemCategory saveItemCategory,
  })  : _getItemCategories = getItemCategories,
        _saveItemCategory = saveItemCategory,
        super(const ItemCategoryListState()) {
    on<ItemCategoryListStarted>(_onLoad);
    on<ItemCategoryListRefreshed>(_onLoad);
    on<ItemCategorySaveRequested>(_onSave, transformer: droppable());
    on<ItemCategoryListNoticeConsumed>(_onNoticeConsumed);
  }

  final GetItemCategories _getItemCategories;
  final SaveItemCategory _saveItemCategory;

  Future<void> _onLoad(
    ItemCategoryListEvent event,
    Emitter<ItemCategoryListState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, clearError: true));
    try {
      final categories = await _getItemCategories(
        const GetItemCategoriesParams(includeInactive: true),
      );
      emit(
        state.copyWith(
          status: Status.success,
          categories: categories,
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
    ItemCategorySaveRequested event,
    Emitter<ItemCategoryListState> emit,
  ) async {
    emit(state.copyWith(status: Status.submitting, clearError: true));
    try {
      await _saveItemCategory(event.params);
      final categories = await _getItemCategories(
        const GetItemCategoriesParams(includeInactive: true),
      );
      emit(
        state.copyWith(
          status: Status.success,
          categories: categories,
          notice: event.params.id == null
              ? 'Category created'
              : 'Category updated',
          clearError: true,
        ),
      );
    } on Failure catch (e) {
      emit(
        state.copyWith(
          status: Status.failure,
          error: e.message,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  void _onNoticeConsumed(
    ItemCategoryListNoticeConsumed event,
    Emitter<ItemCategoryListState> emit,
  ) {
    emit(state.copyWith(clearNotice: true));
  }
}

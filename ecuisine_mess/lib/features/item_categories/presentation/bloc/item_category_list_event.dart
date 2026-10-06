part of 'item_category_list_bloc.dart';

sealed class ItemCategoryListEvent extends Equatable {
  const ItemCategoryListEvent();

  @override
  List<Object?> get props => [];
}

final class ItemCategoryListStarted extends ItemCategoryListEvent {
  const ItemCategoryListStarted();
}

final class ItemCategoryListRefreshed extends ItemCategoryListEvent {
  const ItemCategoryListRefreshed();
}

final class ItemCategorySaveRequested extends ItemCategoryListEvent {
  const ItemCategorySaveRequested(this.params);

  final SaveItemCategoryParams params;

  @override
  List<Object?> get props => [params];
}

final class ItemCategoryListNoticeConsumed extends ItemCategoryListEvent {
  const ItemCategoryListNoticeConsumed();
}

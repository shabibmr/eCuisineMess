part of 'item_list_bloc.dart';

sealed class ItemListEvent extends Equatable {
  const ItemListEvent();

  @override
  List<Object?> get props => [];
}

final class ItemListStarted extends ItemListEvent {
  const ItemListStarted();
}

final class ItemListRefreshed extends ItemListEvent {
  const ItemListRefreshed();
}

final class ItemSaveRequested extends ItemListEvent {
  const ItemSaveRequested(this.params);

  final SaveItemParams params;

  @override
  List<Object?> get props => [params];
}

final class ItemDeleteRequested extends ItemListEvent {
  const ItemDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class ItemListNoticeConsumed extends ItemListEvent {
  const ItemListNoticeConsumed();
}

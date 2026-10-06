part of 'cuisine_editor_bloc.dart';

sealed class CuisineEditorEvent extends Equatable {
  const CuisineEditorEvent();

  @override
  List<Object?> get props => [];
}

final class CuisineEditorStarted extends CuisineEditorEvent {
  const CuisineEditorStarted({this.cuisineId});

  final String? cuisineId;

  @override
  List<Object?> get props => [cuisineId];
}

final class CuisineEditorNameChanged extends CuisineEditorEvent {
  const CuisineEditorNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class CuisineEditorDescriptionChanged extends CuisineEditorEvent {
  const CuisineEditorDescriptionChanged(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

final class CuisineEditorActiveToggled extends CuisineEditorEvent {
  const CuisineEditorActiveToggled(this.isActive);

  final bool isActive;

  @override
  List<Object?> get props => [isActive];
}

final class CuisineEditorItemsMapped extends CuisineEditorEvent {
  const CuisineEditorItemsMapped(this.newItems);

  final List<CuisineItemMapping> newItems;

  @override
  List<Object?> get props => [newItems];
}

final class CuisineEditorItemsRemoved extends CuisineEditorEvent {
  const CuisineEditorItemsRemoved(this.itemIds);

  final List<String> itemIds;

  @override
  List<Object?> get props => [itemIds];
}

final class CuisineEditorItemQtyChanged extends CuisineEditorEvent {
  const CuisineEditorItemQtyChanged({
    required this.itemId,
    required this.qty,
  });

  final String itemId;
  final double qty;

  @override
  List<Object?> get props => [itemId, qty];
}

final class CuisineEditorCopyMappingRequested extends CuisineEditorEvent {
  const CuisineEditorCopyMappingRequested(this.sourceCuisineId);

  final String sourceCuisineId;

  @override
  List<Object?> get props => [sourceCuisineId];
}

final class CuisineEditorSubmitted extends CuisineEditorEvent {
  const CuisineEditorSubmitted();
}

final class CuisineEditorDismissConflict extends CuisineEditorEvent {
  const CuisineEditorDismissConflict();
}

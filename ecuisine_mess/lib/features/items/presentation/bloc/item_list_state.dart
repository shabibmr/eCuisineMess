part of 'item_list_bloc.dart';

final class ItemListState extends Equatable {
  const ItemListState({
    this.status = Status.initial,
    this.items = const [],
    this.categories = const [],
    this.uoms = const [],
    this.error,
    this.notice,
  });

  final Status status;
  final List<Item> items;
  final List<ItemCategory> categories;
  final List<Uom> uoms;
  final String? error;
  final String? notice;

  List<ItemCategory> get activeCategories =>
      categories.where((c) => c.isActive).toList();

  ItemListState copyWith({
    Status? status,
    List<Item>? items,
    List<ItemCategory>? categories,
    List<Uom>? uoms,
    String? error,
    String? notice,
    bool clearError = false,
    bool clearNotice = false,
  }) {
    return ItemListState(
      status: status ?? this.status,
      items: items ?? this.items,
      categories: categories ?? this.categories,
      uoms: uoms ?? this.uoms,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props =>
      [status, items, categories, uoms, error, notice];
}

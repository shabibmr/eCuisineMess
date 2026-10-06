part of 'item_category_list_bloc.dart';

final class ItemCategoryListState extends Equatable {
  const ItemCategoryListState({
    this.status = Status.initial,
    this.categories = const [],
    this.error,
    this.notice,
  });

  final Status status;
  final List<ItemCategory> categories;
  final String? error;
  final String? notice;

  ItemCategoryListState copyWith({
    Status? status,
    List<ItemCategory>? categories,
    String? error,
    String? notice,
    bool clearError = false,
    bool clearNotice = false,
  }) {
    return ItemCategoryListState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      error: clearError ? null : (error ?? this.error),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [status, categories, error, notice];
}

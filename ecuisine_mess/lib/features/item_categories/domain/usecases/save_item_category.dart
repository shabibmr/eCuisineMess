import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/item_categories/domain/repositories/item_category_repository.dart';
import 'package:equatable/equatable.dart';

class SaveItemCategory extends UseCase<void, SaveItemCategoryParams> {
  SaveItemCategory(this._repository);

  final ItemCategoryRepository _repository;

  @override
  Future<void> call(SaveItemCategoryParams params) async {
    if (params.id == null) {
      await _repository.createCategory(
        name: params.name,
        sortOrder: params.sortOrder,
        isActive: params.isActive,
      );
    } else {
      await _repository.updateCategory(
        id: params.id!,
        name: params.name,
        sortOrder: params.sortOrder,
        isActive: params.isActive,
      );
    }
  }
}

class SaveItemCategoryParams extends Equatable {
  const SaveItemCategoryParams({
    this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });

  final String? id;
  final String name;
  final int sortOrder;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, sortOrder, isActive];
}

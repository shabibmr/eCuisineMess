import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/items/domain/repositories/item_repository.dart';
import 'package:equatable/equatable.dart';

class SaveItem extends UseCase<void, SaveItemParams> {
  SaveItem(this._repository);

  final ItemRepository _repository;

  @override
  Future<void> call(SaveItemParams params) async {
    if (params.id == null) {
      await _repository.createItem(
        name: params.name,
        categoryId: params.categoryId,
        uomId: params.uomId,
        isActive: params.isActive,
      );
    } else {
      await _repository.updateItem(
        id: params.id!,
        name: params.name,
        categoryId: params.categoryId,
        uomId: params.uomId,
        isActive: params.isActive,
      );
    }
  }
}

class SaveItemParams extends Equatable {
  const SaveItemParams({
    this.id,
    required this.name,
    required this.categoryId,
    required this.uomId,
    this.isActive = true,
  });

  final String? id;
  final String name;
  final String categoryId;
  final String uomId;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, categoryId, uomId, isActive];
}

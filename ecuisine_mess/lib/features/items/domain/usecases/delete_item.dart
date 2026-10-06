import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item_delete_result.dart';
import 'package:ecuisine_mess/features/items/domain/repositories/item_repository.dart';
import 'package:equatable/equatable.dart';

class DeleteItem extends UseCase<ItemDeleteResult, DeleteItemParams> {
  DeleteItem(this._repository);

  final ItemRepository _repository;

  @override
  Future<ItemDeleteResult> call(DeleteItemParams params) {
    return _repository.deleteItem(params.id);
  }
}

class DeleteItemParams extends Equatable {
  const DeleteItemParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

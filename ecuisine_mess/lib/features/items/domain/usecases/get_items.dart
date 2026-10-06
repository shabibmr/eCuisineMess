import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/items/domain/entities/item.dart';
import 'package:ecuisine_mess/features/items/domain/repositories/item_repository.dart';
import 'package:equatable/equatable.dart';

class GetItems extends UseCase<List<Item>, GetItemsParams> {
  GetItems(this._repository);

  final ItemRepository _repository;

  @override
  Future<List<Item>> call(GetItemsParams params) {
    return _repository.getItems(
      includeInactive: params.includeInactive,
      categoryId: params.categoryId,
    );
  }
}

class GetItemsParams extends Equatable {
  const GetItemsParams({
    this.includeInactive = true,
    this.categoryId,
  });

  final bool includeInactive;
  final String? categoryId;

  @override
  List<Object?> get props => [includeInactive, categoryId];
}

import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/item_categories/domain/entities/item_category.dart';
import 'package:ecuisine_mess/features/item_categories/domain/repositories/item_category_repository.dart';
import 'package:equatable/equatable.dart';

class GetItemCategories
    extends UseCase<List<ItemCategory>, GetItemCategoriesParams> {
  GetItemCategories(this._repository);

  final ItemCategoryRepository _repository;

  @override
  Future<List<ItemCategory>> call(GetItemCategoriesParams params) {
    return _repository.getCategories(includeInactive: params.includeInactive);
  }
}

class GetItemCategoriesParams extends Equatable {
  const GetItemCategoriesParams({this.includeInactive = true});

  final bool includeInactive;

  @override
  List<Object?> get props => [includeInactive];
}

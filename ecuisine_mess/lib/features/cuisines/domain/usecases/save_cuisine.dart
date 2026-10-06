import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping_input.dart';
import 'package:ecuisine_mess/features/cuisines/domain/repositories/cuisine_repository.dart';
import 'package:equatable/equatable.dart';

class SaveCuisine extends UseCase<String, SaveCuisineParams> {
  SaveCuisine(this._repository);

  final CuisineRepository _repository;

  @override
  Future<String> call(SaveCuisineParams params) {
    return _repository.saveCuisine(
      id: params.id,
      cuisineName: params.cuisineName,
      description: params.description,
      isActive: params.isActive,
      items: params.items,
    );
  }
}

class SaveCuisineParams extends Equatable {
  const SaveCuisineParams({
    this.id,
    required this.cuisineName,
    this.description,
    this.isActive = true,
    this.items = const [],
  });

  final String? id;
  final String cuisineName;
  final String? description;
  final bool isActive;
  final List<CuisineItemMappingInput> items;

  @override
  List<Object?> get props => [id, cuisineName, description, isActive, items];
}

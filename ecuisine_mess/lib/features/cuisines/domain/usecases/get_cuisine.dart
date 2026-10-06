import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/repositories/cuisine_repository.dart';

class GetCuisine extends UseCase<Cuisine, String> {
  GetCuisine(this._repository);

  final CuisineRepository _repository;

  @override
  Future<Cuisine> call(String id) {
    return _repository.getCuisine(id);
  }
}

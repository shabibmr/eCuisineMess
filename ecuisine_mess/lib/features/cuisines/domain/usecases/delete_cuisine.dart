import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_delete_result.dart';
import 'package:ecuisine_mess/features/cuisines/domain/repositories/cuisine_repository.dart';

class DeleteCuisine extends UseCase<CuisineDeleteResult, String> {
  DeleteCuisine(this._repository);

  final CuisineRepository _repository;

  @override
  Future<CuisineDeleteResult> call(String id) {
    return _repository.deleteCuisine(id);
  }
}

import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/cuisines/domain/repositories/cuisine_repository.dart';
import 'package:equatable/equatable.dart';

class CopyCuisineMapping extends UseCase<int, CopyCuisineMappingParams> {
  CopyCuisineMapping(this._repository);

  final CuisineRepository _repository;

  @override
  Future<int> call(CopyCuisineMappingParams params) {
    return _repository.copyMapping(
      targetCuisineId: params.targetCuisineId,
      sourceCuisineId: params.sourceCuisineId,
    );
  }
}

class CopyCuisineMappingParams extends Equatable {
  const CopyCuisineMappingParams({
    required this.targetCuisineId,
    required this.sourceCuisineId,
  });

  final String targetCuisineId;
  final String sourceCuisineId;

  @override
  List<Object?> get props => [targetCuisineId, sourceCuisineId];
}

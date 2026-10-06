import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine.dart';
import 'package:ecuisine_mess/features/cuisines/domain/repositories/cuisine_repository.dart';
import 'package:equatable/equatable.dart';

class GetCuisines extends UseCase<List<Cuisine>, GetCuisinesParams> {
  GetCuisines(this._repository);

  final CuisineRepository _repository;

  @override
  Future<List<Cuisine>> call(GetCuisinesParams params) {
    return _repository.getCuisines(
      includeInactive: params.includeInactive,
    );
  }
}

class GetCuisinesParams extends Equatable {
  const GetCuisinesParams({this.includeInactive = false});

  final bool includeInactive;

  @override
  List<Object?> get props => [includeInactive];
}

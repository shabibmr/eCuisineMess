import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/features/members/domain/repositories/member_repository.dart';
import 'package:equatable/equatable.dart';

class GetCuisineOptions
    extends UseCase<List<CuisineOption>, GetCuisineOptionsParams> {
  GetCuisineOptions(this._repository);

  final MemberRepository _repository;

  @override
  Future<List<CuisineOption>> call(GetCuisineOptionsParams params) {
    return _repository.getCuisineOptions(
      includeInactive: params.includeInactive,
    );
  }
}

class GetCuisineOptionsParams extends Equatable {
  const GetCuisineOptionsParams({this.includeInactive = false});

  final bool includeInactive;

  @override
  List<Object?> get props => [includeInactive];
}

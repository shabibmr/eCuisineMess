import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member.dart';
import 'package:ecuisine_mess/features/members/domain/repositories/member_repository.dart';
import 'package:equatable/equatable.dart';

class GetMembers extends UseCase<List<Member>, GetMembersParams> {
  GetMembers(this._repository);

  final MemberRepository _repository;

  @override
  Future<List<Member>> call(GetMembersParams params) {
    return _repository.getMembers(
      search: params.search,
      status: params.status,
    );
  }
}

class GetMembersParams extends Equatable {
  const GetMembersParams({this.search, this.status});

  final String? search;
  final String? status;

  @override
  List<Object?> get props => [search, status];
}

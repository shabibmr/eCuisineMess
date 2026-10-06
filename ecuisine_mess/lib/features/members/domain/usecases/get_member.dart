import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member.dart';
import 'package:ecuisine_mess/features/members/domain/repositories/member_repository.dart';
import 'package:equatable/equatable.dart';

class GetMember extends UseCase<Member, GetMemberParams> {
  GetMember(this._repository);

  final MemberRepository _repository;

  @override
  Future<Member> call(GetMemberParams params) {
    return _repository.getMember(params.id);
  }
}

class GetMemberParams extends Equatable {
  const GetMemberParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

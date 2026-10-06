import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member_delete_result.dart';
import 'package:ecuisine_mess/features/members/domain/repositories/member_repository.dart';
import 'package:equatable/equatable.dart';

class DeleteMember extends UseCase<MemberDeleteResult, DeleteMemberParams> {
  DeleteMember(this._repository);

  final MemberRepository _repository;

  @override
  Future<MemberDeleteResult> call(DeleteMemberParams params) {
    return _repository.deleteMember(params.id);
  }
}

class DeleteMemberParams extends Equatable {
  const DeleteMemberParams(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

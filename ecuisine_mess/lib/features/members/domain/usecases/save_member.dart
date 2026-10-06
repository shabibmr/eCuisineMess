import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/features/members/domain/repositories/member_repository.dart';
import 'package:equatable/equatable.dart';

class SaveMember extends UseCase<void, SaveMemberParams> {
  SaveMember(this._repository);

  final MemberRepository _repository;

  @override
  Future<void> call(SaveMemberParams params) async {
    if (params.id == null) {
      await _repository.createMember(
        name: params.name,
        rfidTag: params.rfidTag,
        phone: params.phone,
        email: params.email,
        cuisineId: params.cuisineId,
        validityStart: params.validityStart,
        validityEnd: params.validityEnd,
        status: params.status,
      );
    } else {
      await _repository.updateMember(
        id: params.id!,
        name: params.name,
        rfidTag: params.rfidTag,
        phone: params.phone,
        email: params.email,
        cuisineId: params.cuisineId,
        validityStart: params.validityStart,
        validityEnd: params.validityEnd,
        status: params.status,
      );
    }
  }
}

class SaveMemberParams extends Equatable {
  const SaveMemberParams({
    this.id,
    required this.name,
    required this.rfidTag,
    this.phone,
    this.email,
    this.cuisineId,
    required this.validityStart,
    required this.validityEnd,
    this.status = 'ACTIVE',
  });

  final String? id;
  final String name;
  final String rfidTag;
  final String? phone;
  final String? email;
  final String? cuisineId;
  final String validityStart;
  final String validityEnd;
  final String status;

  @override
  List<Object?> get props => [
        id,
        name,
        rfidTag,
        phone,
        email,
        cuisineId,
        validityStart,
        validityEnd,
        status,
      ];
}

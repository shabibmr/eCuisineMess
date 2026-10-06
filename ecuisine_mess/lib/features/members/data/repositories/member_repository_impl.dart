import 'package:ecuisine_mess/core/error/exception_mapper.dart';
import 'package:ecuisine_mess/features/members/data/datasources/member_remote_datasource.dart';
import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member_delete_result.dart';
import 'package:ecuisine_mess/features/members/domain/entities/rfid_availability.dart';
import 'package:ecuisine_mess/features/members/domain/repositories/member_repository.dart';

class MemberRepositoryImpl implements MemberRepository {
  MemberRepositoryImpl(this._remote);

  final MemberRemoteDataSource _remote;

  @override
  Future<List<Member>> getMembers({String? search, String? status}) async {
    try {
      final list = await _remote.getMembers(search: search, status: status);
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<Member> getMember(String id) async {
    try {
      final model = await _remote.getMember(id);
      return model.toEntity();
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<String> createMember({
    required String name,
    required String rfidTag,
    String? phone,
    String? email,
    String? cuisineId,
    required String validityStart,
    required String validityEnd,
    String status = 'ACTIVE',
  }) async {
    try {
      return await _remote.createMember(
        name: name,
        rfidTag: rfidTag,
        phone: phone,
        email: email,
        cuisineId: cuisineId,
        validityStart: validityStart,
        validityEnd: validityEnd,
        status: status,
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<void> updateMember({
    required String id,
    String? name,
    String? rfidTag,
    String? phone,
    String? email,
    String? cuisineId,
    String? validityStart,
    String? validityEnd,
    String? status,
  }) async {
    try {
      await _remote.updateMember(
        id: id,
        name: name,
        rfidTag: rfidTag,
        phone: phone,
        email: email,
        cuisineId: cuisineId,
        validityStart: validityStart,
        validityEnd: validityEnd,
        status: status,
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<RfidAvailability> checkRfidAvailable({
    required String tag,
    String? excludeMemberId,
  }) async {
    try {
      final found = await _remote.getMemberByRfid(tag.trim());
      if (found == null) {
        return const RfidAvailability.available();
      }
      if (excludeMemberId != null && found.id == excludeMemberId) {
        return const RfidAvailability.available();
      }
      return RfidAvailability.taken(
        conflictingMemberId: found.id,
        conflictingMemberName: found.name,
      );
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<MemberDeleteResult> deleteMember(String id) async {
    try {
      return await _remote.deleteMember(id);
    } on Object catch (e) {
      throw mapException(e);
    }
  }

  @override
  Future<List<CuisineOption>> getCuisineOptions({
    bool includeInactive = false,
  }) async {
    try {
      final list =
          await _remote.getCuisines(includeInactive: includeInactive);
      return list.map((m) => m.toEntity()).toList();
    } on Object catch (e) {
      throw mapException(e);
    }
  }
}

import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member.dart';
import 'package:ecuisine_mess/features/members/domain/entities/member_delete_result.dart';
import 'package:ecuisine_mess/features/members/domain/entities/rfid_availability.dart';

abstract interface class MemberRepository {
  Future<List<Member>> getMembers({String? search, String? status});

  Future<Member> getMember(String id);

  Future<String> createMember({
    required String name,
    required String rfidTag,
    String? phone,
    String? email,
    String? cuisineId,
    required String validityStart,
    required String validityEnd,
    String status = 'ACTIVE',
  });

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
  });

  Future<RfidAvailability> checkRfidAvailable({
    required String tag,
    String? excludeMemberId,
  });

  Future<MemberDeleteResult> deleteMember(String id);

  Future<List<CuisineOption>> getCuisineOptions({
    bool includeInactive = false,
  });
}

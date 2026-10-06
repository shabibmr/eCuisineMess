import 'package:ecuisine_mess/features/members/data/models/member_model.dart';
import 'package:ecuisine_mess/features/members/domain/entities/rfid_availability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MemberModel maps API JSON fields', () {
    final model = MemberModel.fromJson({
      'id': 'm1',
      'name': 'Rahul',
      'rfid_tag': 'RFID-001',
      'phone': '999',
      'email': 'r@x.com',
      'cuisine_id': 'cu1',
      'cuisine_name': 'South Indian',
      'validity_start': '2026-01-01',
      'validity_end': '2026-12-31',
      'status': 'ACTIVE',
      'days_left': 12,
    });

    final member = model.toEntity();
    expect(member.rfidTag, 'RFID-001');
    expect(member.cuisineName, 'South Indian');
    expect(member.daysLeft, 12);
    expect(member.isExpired, isFalse);
  });

  test('RfidAvailability taken vs available', () {
    const available = RfidAvailability.available();
    expect(available.available, isTrue);

    const taken = RfidAvailability.taken(
      conflictingMemberId: 'm2',
      conflictingMemberName: 'Other',
    );
    expect(taken.available, isFalse);
    expect(taken.conflictingMemberName, 'Other');
  });
}

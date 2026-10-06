import 'package:ecuisine_mess/features/members/domain/entities/member.dart';

class MemberModel {
  const MemberModel({
    required this.id,
    required this.name,
    required this.rfidTag,
    this.phone,
    this.email,
    this.cuisineId,
    this.cuisineName,
    required this.validityStart,
    required this.validityEnd,
    this.status = 'ACTIVE',
    this.daysLeft = 0,
  });

  final String id;
  final String name;
  final String rfidTag;
  final String? phone;
  final String? email;
  final String? cuisineId;
  final String? cuisineName;
  final String validityStart;
  final String validityEnd;
  final String status;
  final int daysLeft;

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      rfidTag: json['rfid_tag']?.toString() ?? '',
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      cuisineId: json['cuisine_id']?.toString(),
      cuisineName: json['cuisine_name']?.toString(),
      validityStart: json['validity_start']?.toString() ?? '',
      validityEnd: json['validity_end']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      daysLeft: json['days_left'] is int
          ? json['days_left'] as int
          : int.tryParse(json['days_left']?.toString() ?? '0') ?? 0,
    );
  }

  Member toEntity() => Member(
        id: id,
        name: name,
        rfidTag: rfidTag,
        phone: phone,
        email: email,
        cuisineId: cuisineId,
        cuisineName: cuisineName,
        validityStart: validityStart,
        validityEnd: validityEnd,
        status: status,
        daysLeft: daysLeft,
      );
}

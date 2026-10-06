import 'package:equatable/equatable.dart';

class Member extends Equatable {
  const Member({
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

  bool get isExpired =>
      status.toUpperCase() == 'EXPIRED' || daysLeft < 0;

  bool get isExpiringSoon => !isExpired && daysLeft <= 7;

  @override
  List<Object?> get props => [
        id,
        name,
        rfidTag,
        phone,
        email,
        cuisineId,
        cuisineName,
        validityStart,
        validityEnd,
        status,
        daysLeft,
      ];
}

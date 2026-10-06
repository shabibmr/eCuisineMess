class Member {
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

  Member({
    required this.id,
    required this.name,
    required this.rfidTag,
    this.phone,
    this.email,
    this.cuisineId,
    this.cuisineName,
    required this.validityStart,
    required this.validityEnd,
    required this.status,
    this.daysLeft = 0,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
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
          ? json['days_left']
          : int.tryParse(json['days_left']?.toString() ?? '0') ?? 0,
    );
  }
}

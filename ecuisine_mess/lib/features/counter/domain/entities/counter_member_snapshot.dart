import 'package:equatable/equatable.dart';

class CounterMemberSnapshot extends Equatable {
  const CounterMemberSnapshot({
    required this.id,
    required this.name,
    this.phone,
    this.cuisineId,
    this.cuisineName,
    this.daysLeft,
    this.status,
  });

  final String id;
  final String name;
  final String? phone;
  final String? cuisineId;
  final String? cuisineName;
  final int? daysLeft;
  final String? status;

  @override
  List<Object?> get props =>
      [id, name, phone, cuisineId, cuisineName, daysLeft, status];
}

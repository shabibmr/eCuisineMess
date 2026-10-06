import 'package:equatable/equatable.dart';

class RfidAvailability extends Equatable {
  const RfidAvailability({
    required this.available,
    this.conflictingMemberId,
    this.conflictingMemberName,
  });

  const RfidAvailability.available()
      : available = true,
        conflictingMemberId = null,
        conflictingMemberName = null;

  const RfidAvailability.taken({
    required this.conflictingMemberId,
    this.conflictingMemberName,
  }) : available = false;

  final bool available;
  final String? conflictingMemberId;
  final String? conflictingMemberName;

  @override
  List<Object?> get props =>
      [available, conflictingMemberId, conflictingMemberName];
}

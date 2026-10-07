import 'package:equatable/equatable.dart';

enum ReportKind {
  attendance('attendance', 'attendance'),
  itemMovement('item-movement', 'item_movement'),
  timeDistribution('time-distribution', 'time_distribution'),
  members('members', 'members_register');

  const ReportKind(this.path, this.fileStem);

  /// Segment under `/reports/`.
  final String path;

  /// Base name for the saved CSV.
  final String fileStem;
}

/// Query parameters for a report, as sent to the API (empty values omitted).
class ReportQuery extends Equatable {
  const ReportQuery([this.params = const {}]);

  final Map<String, String> params;

  @override
  List<Object?> get props => [params];
}

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.memberId,
    required this.memberName,
    required this.cuisineName,
    required this.billDate,
    required this.mealType,
    required this.tokenNumber,
    required this.billTime,
  });

  final String memberId;
  final String memberName;
  final String cuisineName;
  final String billDate;
  final String mealType;
  final String tokenNumber;
  final String billTime;

  @override
  List<Object?> get props => [
    memberId,
    memberName,
    cuisineName,
    billDate,
    mealType,
    tokenNumber,
    billTime,
  ];
}

class AbsenteeRecord extends Equatable {
  const AbsenteeRecord({
    required this.memberId,
    required this.memberName,
    this.cuisineName,
    this.phone,
    this.validityEnd,
  });

  final String memberId;
  final String memberName;
  final String? cuisineName;
  final String? phone;
  final String? validityEnd;

  @override
  List<Object?> get props => [
    memberId,
    memberName,
    cuisineName,
    phone,
    validityEnd,
  ];
}

class AttendanceReport extends Equatable {
  const AttendanceReport({
    required this.absenteesOnly,
    this.records = const [],
    this.absentees = const [],
  });

  final bool absenteesOnly;
  final List<AttendanceRecord> records;
  final List<AbsenteeRecord> absentees;

  int get count => absenteesOnly ? absentees.length : records.length;

  @override
  List<Object?> get props => [absenteesOnly, records, absentees];
}

class ItemMovementRow extends Equatable {
  const ItemMovementRow({
    required this.itemName,
    required this.cuisineName,
    required this.totalQuantity,
    required this.servedCount,
    this.unit,
    this.category,
  });

  final String itemName;
  final String cuisineName;
  final String? unit;
  final String? category;
  final double totalQuantity;
  final int servedCount;

  @override
  List<Object?> get props => [
    itemName,
    cuisineName,
    unit,
    category,
    totalQuantity,
    servedCount,
  ];
}

class TimeSlot extends Equatable {
  const TimeSlot({
    required this.label,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.total,
  });

  final String label;
  final int breakfast;
  final int lunch;
  final int dinner;
  final int total;

  @override
  List<Object?> get props => [label, breakfast, lunch, dinner, total];
}

class TimeDistributionReport extends Equatable {
  const TimeDistributionReport({
    required this.intervalMinutes,
    required this.totalTokens,
    required this.peakCount,
    this.firstTokenTime,
    this.lastTokenTime,
    this.peakSlot,
    this.slots = const [],
  });

  final int intervalMinutes;
  final int totalTokens;
  final String? firstTokenTime;
  final String? lastTokenTime;
  final String? peakSlot;
  final int peakCount;
  final List<TimeSlot> slots;

  @override
  List<Object?> get props => [
    intervalMinutes,
    totalTokens,
    firstTokenTime,
    lastTokenTime,
    peakSlot,
    peakCount,
    slots,
  ];
}

class MemberRegisterRow extends Equatable {
  const MemberRegisterRow({
    required this.id,
    required this.name,
    required this.rfidTag,
    required this.cuisineName,
    required this.status,
    this.phone,
    this.email,
    this.validityStart,
    this.validityEnd,
    this.daysLeft,
  });

  final String id;
  final String name;
  final String rfidTag;
  final String cuisineName;

  /// Derived: `ACTIVE`, `EXPIRED` or `SUSPENDED`.
  final String status;
  final String? phone;
  final String? email;
  final String? validityStart;
  final String? validityEnd;
  final int? daysLeft;

  @override
  List<Object?> get props => [
    id,
    name,
    rfidTag,
    cuisineName,
    status,
    phone,
    email,
    validityStart,
    validityEnd,
    daysLeft,
  ];
}

class MembersRegister extends Equatable {
  const MembersRegister({
    required this.total,
    required this.active,
    required this.expired,
    required this.suspended,
    this.byCuisine = const {},
    this.members = const [],
  });

  final int total;
  final int active;
  final int expired;
  final int suspended;
  final Map<String, int> byCuisine;
  final List<MemberRegisterRow> members;

  @override
  List<Object?> get props => [
    total,
    active,
    expired,
    suspended,
    byCuisine,
    members,
  ];
}

import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';

/// JSON → entity parsers for `/reports/*` responses.
abstract final class ReportModels {
  static String _s(Object? v, [String fallback = '']) =>
      v == null ? fallback : v.toString();

  static String? _sn(Object? v) => v?.toString();

  static int _i(Object? v) => v is num ? v.toInt() : int.tryParse(_s(v)) ?? 0;

  static double _d(Object? v) =>
      v is num ? v.toDouble() : double.tryParse(_s(v)) ?? 0;

  static List<Map<String, dynamic>> _rows(Object? v) => v is List
      ? [for (final e in v) Map<String, dynamic>.from(e as Map)]
      : const [];

  static AttendanceReport attendance(Map<String, dynamic> json) {
    final absentees = json['view'] == 'absentees';
    final rows = _rows(json['records']);
    return AttendanceReport(
      absenteesOnly: absentees,
      records: absentees
          ? const []
          : [
              for (final r in rows)
                AttendanceRecord(
                  memberId: _s(r['member_id']),
                  memberName: _s(r['name']),
                  cuisineName: _s(r['cuisine_name']),
                  billDate: _s(r['bill_date']),
                  mealType: _s(r['meal_type']),
                  tokenNumber: _s(r['token_number']),
                  billTime: _s(r['bill_time']),
                ),
            ],
      absentees: absentees
          ? [
              for (final r in rows)
                AbsenteeRecord(
                  memberId: _s(r['member_id']),
                  memberName: _s(r['member_name']),
                  cuisineName: _sn(r['cuisine_name']),
                  phone: _sn(r['phone']),
                  validityEnd: _sn(r['validity_end']),
                ),
            ]
          : const [],
    );
  }

  static List<ItemMovementRow> itemMovement(Object? json) => [
    for (final r in _rows(json))
      ItemMovementRow(
        itemName: _s(r['item_name']),
        cuisineName: _s(r['cuisine_name']),
        unit: _sn(r['unit']),
        category: _sn(r['category']),
        totalQuantity: _d(r['total_quantity']),
        servedCount: _i(r['served_count']),
      ),
  ];

  static TimeDistributionReport timeDistribution(Map<String, dynamic> json) {
    return TimeDistributionReport(
      intervalMinutes: _i(json['interval_minutes']),
      totalTokens: _i(json['total_tokens']),
      firstTokenTime: _sn(json['first_token_time']),
      lastTokenTime: _sn(json['last_token_time']),
      peakSlot: _sn(json['peak_slot']),
      peakCount: _i(json['peak_count']),
      slots: [
        for (final r in _rows(json['slots']))
          TimeSlot(
            label: _s(r['slot']),
            breakfast: _i(r['BREAKFAST']),
            lunch: _i(r['LUNCH']),
            dinner: _i(r['DINNER']),
            total: _i(r['total']),
          ),
      ],
    );
  }

  static MembersRegister membersRegister(Map<String, dynamic> json) {
    final summary = json['summary'] is Map
        ? Map<String, dynamic>.from(json['summary'] as Map)
        : const <String, dynamic>{};
    final byCuisine = summary['by_cuisine'] is Map
        ? {
            for (final e in (summary['by_cuisine'] as Map).entries)
              e.key.toString(): _i(e.value),
          }
        : const <String, int>{};
    return MembersRegister(
      total: _i(json['total_members']),
      active: _i(summary['active']),
      expired: _i(summary['expired']),
      suspended: _i(summary['suspended']),
      byCuisine: byCuisine,
      members: [
        for (final r in _rows(json['members']))
          MemberRegisterRow(
            id: _s(r['id']),
            name: _s(r['name']),
            rfidTag: _s(r['rfid_tag']),
            cuisineName: _s(r['cuisine_name'], 'Unassigned'),
            status: _s(r['status']),
            phone: _sn(r['phone']),
            email: _sn(r['email']),
            validityStart: _sn(r['validity_start']),
            validityEnd: _sn(r['validity_end']),
            daysLeft: r['days_left'] == null ? null : _i(r['days_left']),
          ),
      ],
    );
  }
}

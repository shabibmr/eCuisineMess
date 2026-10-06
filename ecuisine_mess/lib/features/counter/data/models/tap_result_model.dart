import 'package:ecuisine_mess/features/counter/domain/entities/counter_line_item.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/counter_member_snapshot.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/counter_tap_result.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/today_meal_strip.dart';

class TapResultModel {
  const TapResultModel({
    required this.success,
    this.errorCode,
    this.message,
    this.member,
    this.mealType,
    this.items = const [],
    this.totalAmount = 0,
    this.existingBill,
    this.today = TodayMealStrip.empty,
  });

  final bool success;
  final String? errorCode;
  final String? message;
  final CounterMemberSnapshot? member;
  final String? mealType;
  final List<CounterLineItem> items;
  final double totalAmount;
  final ExistingBillRef? existingBill;
  final TodayMealStrip today;

  factory TapResultModel.fromJson(Map<String, dynamic> json) {
    final rawMember = json['member'];
    CounterMemberSnapshot? member;
    if (rawMember is Map) {
      final m = Map<String, dynamic>.from(rawMember);
      member = CounterMemberSnapshot(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        phone: m['phone']?.toString(),
        cuisineId: m['cuisine_id']?.toString(),
        cuisineName: m['cuisine_name']?.toString(),
        daysLeft: int.tryParse(m['days_left']?.toString() ?? ''),
        status: m['status']?.toString(),
      );
    }

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      final rawId = map['id'] ?? map['item_id'];
      return CounterLineItem(
        id: rawId?.toString() ?? '',
        name: map['item_name']?.toString() ?? map['name']?.toString() ?? '',
        unit: map['unit']?.toString() ??
            map['uom_name']?.toString() ??
            'Nos',
        category: map['category_name']?.toString() ??
            map['category']?.toString() ??
            'Main',
        quantity:
            double.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      );
    }).toList();

    ExistingBillRef? existing;
    final rawExisting = json['existing_bill'];
    if (rawExisting is Map) {
      final e = Map<String, dynamic>.from(rawExisting);
      existing = ExistingBillRef(
        id: e['id']?.toString(),
        billNumber: e['bill_number']?.toString(),
        tokenNumber: e['token_number']?.toString(),
        billTime: e['bill_time']?.toString(),
      );
    }

    TodayMealStrip today = TodayMealStrip.empty;
    final rawToday = json['today'];
    if (rawToday is Map) {
      final t = Map<String, dynamic>.from(rawToday);
      today = TodayMealStrip(
        breakfast: t['BREAKFAST'] == true,
        lunch: t['LUNCH'] == true,
        dinner: t['DINNER'] == true,
      );
    }

    return TapResultModel(
      success: json['success'] == true,
      errorCode: json['error_code']?.toString(),
      message: json['message']?.toString(),
      member: member,
      mealType: json['meal_type']?.toString(),
      items: items,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      existingBill: existing,
      today: today,
    );
  }

  CounterTapResult toEntity() => CounterTapResult(
        success: success,
        errorCode: errorCode,
        message: message,
        member: member,
        mealType: mealType,
        items: items,
        totalAmount: totalAmount,
        existingBill: existingBill,
        today: today,
      );
}

import 'package:ecuisine_mess/features/counter/domain/entities/counter_line_item.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/issued_bill.dart';

class IssuedBillModel {
  const IssuedBillModel({
    this.id,
    this.billNumber,
    required this.tokenNumber,
    required this.date,
    required this.time,
    required this.memberName,
    required this.cuisine,
    required this.mealType,
    this.items = const [],
    this.totalAmount = 0,
    this.isOverride = false,
  });

  final String? id;
  final String? billNumber;
  final String tokenNumber;
  final String date;
  final String time;
  final String memberName;
  final String cuisine;
  final String mealType;
  final List<CounterLineItem> items;
  final double totalAmount;
  final bool isOverride;

  factory IssuedBillModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      if (e is! Map) {
        return CounterLineItem(id: '', name: e.toString());
      }
      final map = Map<String, dynamic>.from(e);
      return CounterLineItem(
        id: (map['id'] ?? map['item_id'])?.toString() ?? '',
        name: map['name']?.toString() ?? map['item_name']?.toString() ?? '',
        unit: map['unit']?.toString() ?? 'Nos',
        category: map['category']?.toString() ?? 'Main',
        quantity:
            double.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      );
    }).toList();

    return IssuedBillModel(
      id: json['id']?.toString(),
      billNumber: json['bill_number']?.toString(),
      tokenNumber: json['token_number']?.toString() ?? 'T-0000',
      date: (json['date'] ?? json['bill_date'])?.toString() ?? '',
      time: (json['time'] ?? json['bill_time'])?.toString() ?? '',
      memberName: json['member_name']?.toString() ?? '',
      cuisine:
          (json['cuisine'] ?? json['cuisine_name'])?.toString() ?? '',
      mealType: json['meal_type']?.toString() ?? '',
      items: items,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      isOverride: json['is_override'] == 1 || json['is_override'] == true,
    );
  }

  IssuedBill toEntity() => IssuedBill(
        id: id,
        billNumber: billNumber,
        tokenNumber: tokenNumber,
        date: date,
        time: time,
        memberName: memberName,
        cuisine: cuisine,
        mealType: mealType,
        items: items,
        totalAmount: totalAmount,
        isOverride: isOverride,
      );
}

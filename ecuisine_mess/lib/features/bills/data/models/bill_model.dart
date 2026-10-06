import 'package:ecuisine_mess/features/bills/domain/entities/bill.dart';

class BillModel {
  const BillModel({
    required this.id,
    required this.billNumber,
    required this.tokenNumber,
    required this.billDate,
    required this.billTime,
    required this.memberName,
    required this.cuisineName,
    required this.mealType,
    this.totalAmount = 0,
    required this.status,
    this.isOverride = false,
    this.overrideBy,
    this.overrideReason,
    this.items = const [],
  });

  final String id;
  final String billNumber;
  final String tokenNumber;
  final String billDate;
  final String billTime;
  final String memberName;
  final String cuisineName;
  final String mealType;
  final double totalAmount;
  final String status;
  final bool isOverride;
  final String? overrideBy;
  final String? overrideReason;
  final List<BillLine> items;

  factory BillModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      if (e is! Map) {
        return BillLine(name: e.toString());
      }
      final m = Map<String, dynamic>.from(e);
      return BillLine(
        itemId: (m['item_id'] ?? m['id'])?.toString(),
        name: m['item_name']?.toString() ?? m['name']?.toString() ?? '',
        quantity: double.tryParse(m['quantity']?.toString() ?? '1') ?? 1,
        unitPrice:
            double.tryParse(m['unit_price']?.toString() ?? '0') ?? 0,
        totalPrice:
            double.tryParse(m['total_price']?.toString() ?? '0') ?? 0,
      );
    }).toList();

    return BillModel(
      id: json['id']?.toString() ?? '',
      billNumber: json['bill_number']?.toString() ?? '',
      tokenNumber: json['token_number']?.toString() ?? '',
      billDate: json['bill_date']?.toString() ?? '',
      billTime: json['bill_time']?.toString() ?? '',
      memberName: json['member_name']?.toString() ?? '',
      cuisineName: json['cuisine_name']?.toString() ??
          json['cuisine']?.toString() ??
          '',
      mealType: json['meal_type']?.toString() ?? '',
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'SERVED',
      isOverride: json['is_override'] == 1 || json['is_override'] == true,
      overrideBy: json['override_by']?.toString(),
      overrideReason: json['override_reason']?.toString(),
      items: items,
    );
  }

  Bill toEntity() => Bill(
        id: id,
        billNumber: billNumber,
        tokenNumber: tokenNumber,
        billDate: billDate,
        billTime: billTime,
        memberName: memberName,
        cuisineName: cuisineName,
        mealType: mealType,
        totalAmount: totalAmount,
        status: status,
        isOverride: isOverride,
        overrideBy: overrideBy,
        overrideReason: overrideReason,
        items: items,
      );
}

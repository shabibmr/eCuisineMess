import 'package:ecuisine_mess/models/item.dart';

class RFIDTapResult {
  final bool success;
  final String? errorCode;
  final String? message;
  final Map<String, dynamic>? memberData;
  final String? mealType;
  final List<MessItem> items;
  final double totalAmount;
  final Map<String, dynamic>? existingBill;

  RFIDTapResult({
    required this.success,
    this.errorCode,
    this.message,
    this.memberData,
    this.mealType,
    this.items = const [],
    this.totalAmount = 0.0,
    this.existingBill,
  });

  factory RFIDTapResult.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<MessItem> parsedItems = rawItems.map((e) => MessItem.fromJson(e as Map<String, dynamic>)).toList();

    return RFIDTapResult(
      success: json['success'] == true,
      errorCode: json['error_code']?.toString(),
      message: json['message']?.toString(),
      memberData: json['member'] is Map<String, dynamic> ? json['member'] : null,
      mealType: json['meal_type']?.toString(),
      items: parsedItems,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0.0') ?? 0.0,
      existingBill: json['existing_bill'] is Map<String, dynamic> ? json['existing_bill'] : null,
    );
  }
}

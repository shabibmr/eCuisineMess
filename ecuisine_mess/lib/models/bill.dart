class Bill {
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
  final List<dynamic> items;

  Bill({
    required this.id,
    required this.billNumber,
    required this.tokenNumber,
    required this.billDate,
    required this.billTime,
    required this.memberName,
    required this.cuisineName,
    required this.mealType,
    this.totalAmount = 0.0,
    required this.status,
    this.isOverride = false,
    this.overrideBy,
    this.overrideReason,
    this.items = const [],
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id']?.toString() ?? '',
      billNumber: json['bill_number']?.toString() ?? '',
      tokenNumber: json['token_number']?.toString() ?? '',
      billDate: json['bill_date']?.toString() ?? '',
      billTime: json['bill_time']?.toString() ?? '',
      memberName: json['member_name']?.toString() ?? '',
      cuisineName: json['cuisine_name']?.toString() ?? '',
      mealType: json['meal_type']?.toString() ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0.0') ?? 0.0,
      status: json['status']?.toString() ?? 'SERVED',
      isOverride: json['is_override'] == 1 || json['is_override'] == true,
      overrideBy: json['override_by']?.toString(),
      overrideReason: json['override_reason']?.toString(),
      items: json['items'] as List<dynamic>? ?? [],
    );
  }
}

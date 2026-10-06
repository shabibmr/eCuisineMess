/// View-model for the printable meal entitlement slip (no Flutter deps).
class TokenSlipData {
  const TokenSlipData({
    required this.tokenNumber,
    required this.memberName,
    required this.cuisine,
    required this.mealType,
    required this.date,
    required this.time,
    this.items = const [],
  });

  final String tokenNumber;
  final String memberName;
  final String cuisine;
  final String mealType;
  final String date;
  final String time;
  final List<TokenSlipLine> items;

  factory TokenSlipData.fromMap(Map<String, dynamic> bill) {
    final rawItems = bill['items'] as List<dynamic>? ?? [];
    return TokenSlipData(
      tokenNumber: bill['token_number']?.toString() ?? 'T-0000',
      memberName: bill['member_name']?.toString() ?? 'Guest',
      cuisine: (bill['cuisine'] ?? bill['cuisine_name'])?.toString() ?? '',
      mealType: bill['meal_type']?.toString() ?? '',
      date: (bill['date'] ?? bill['bill_date'])?.toString() ?? '',
      time: (bill['time'] ?? bill['bill_time'])?.toString() ?? '',
      items: rawItems.map(TokenSlipLine.fromDynamic).toList(),
    );
  }
}

class TokenSlipLine {
  const TokenSlipLine({required this.name, this.quantity = 1});

  final String name;
  final num quantity;

  factory TokenSlipLine.fromDynamic(dynamic item) {
    if (item is TokenSlipLine) return item;
    if (item is Map) {
      return TokenSlipLine(
        name: (item['name'] ?? item['item_name'] ?? '').toString(),
        quantity: num.tryParse(
              (item['quantity'] ?? item['qty'] ?? 1).toString(),
            ) ??
            1,
      );
    }
    return TokenSlipLine(name: item.toString());
  }
}

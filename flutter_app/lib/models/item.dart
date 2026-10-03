class MessItem {
  final int id;
  final String itemCode;
  final String itemName;
  final String category;
  final String unit;
  final bool isActive;
  final double quantity;
  final double price;

  MessItem({
    required this.id,
    required this.itemCode,
    required this.itemName,
    this.category = 'Main',
    this.unit = 'Nos',
    this.isActive = true,
    this.quantity = 1.0,
    this.price = 0.0,
  });

  factory MessItem.fromJson(Map<String, dynamic> json) {
    return MessItem(
      id: json['id'] is int ? json['id'] : (json['item_id'] is int ? json['item_id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      itemCode: json['item_code']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Main',
      unit: json['unit']?.toString() ?? 'Nos',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      quantity: double.tryParse(json['quantity']?.toString() ?? '1.0') ?? 1.0,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}

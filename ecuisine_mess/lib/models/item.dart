class MessItem {
  final String id;
  final String itemName;
  final String? categoryId;
  final String categoryName;
  final String? uomId;
  final String unit;
  final bool isActive;
  final double quantity;
  final double price;

  MessItem({
    required this.id,
    required this.itemName,
    this.categoryId,
    this.categoryName = 'Main',
    this.uomId,
    this.unit = 'Nos',
    this.isActive = true,
    this.quantity = 1.0,
    this.price = 0.0,
  });

  String get category => categoryName;

  factory MessItem.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['item_id'];
    return MessItem(
      id: rawId?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? json['name']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString() ??
          json['category']?.toString() ??
          'Main',
      uomId: json['uom_id']?.toString(),
      unit: json['unit']?.toString() ??
          json['uom_name']?.toString() ??
          'Nos',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      quantity: double.tryParse(json['quantity']?.toString() ?? '1.0') ?? 1.0,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
    );
  }
}

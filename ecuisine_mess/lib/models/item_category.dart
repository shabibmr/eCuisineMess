class ItemCategory {
  final String id;
  final String categoryName;
  final int sortOrder;
  final bool isActive;

  ItemCategory({
    required this.id,
    required this.categoryName,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      id: json['id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      sortOrder: json['sort_order'] is int
          ? json['sort_order']
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }
}

import 'item.dart';

class Cuisine {
  final int id;
  final String cuisineCode;
  final String cuisineName;
  final String? description;
  final bool isActive;
  final List<MessItem> items;

  Cuisine({
    required this.id,
    required this.cuisineCode,
    required this.cuisineName,
    this.description,
    this.isActive = true,
    this.items = const [],
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<MessItem> parsedItems = rawItems.map((e) => MessItem.fromJson(e as Map<String, dynamic>)).toList();

    return Cuisine(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      cuisineCode: json['cuisine_code']?.toString() ?? '',
      cuisineName: json['cuisine_name']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      items: parsedItems,
    );
  }
}

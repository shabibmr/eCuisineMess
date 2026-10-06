import 'package:ecuisine_mess/models/item.dart';

class Cuisine {
  final String id;
  final String cuisineName;
  final String? description;
  final bool isActive;
  final List<MessItem> items;

  Cuisine({
    required this.id,
    required this.cuisineName,
    this.description,
    this.isActive = true,
    this.items = const [],
  });

  factory Cuisine.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<MessItem> parsedItems =
        rawItems.map((e) => MessItem.fromJson(Map<String, dynamic>.from(e))).toList();

    return Cuisine(
      id: json['id']?.toString() ?? '',
      cuisineName: json['cuisine_name']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      items: parsedItems,
    );
  }
}

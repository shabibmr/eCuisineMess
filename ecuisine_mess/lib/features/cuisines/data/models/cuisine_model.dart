import 'package:ecuisine_mess/features/cuisines/data/models/cuisine_item_mapping_model.dart';
import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine.dart';

class CuisineModel {
  const CuisineModel({
    required this.id,
    required this.cuisineName,
    this.description,
    required this.isActive,
    required this.mappedItemsCount,
    required this.activeMembersCount,
    this.items = const [],
  });

  final String id;
  final String cuisineName;
  final String? description;
  final bool isActive;
  final int mappedItemsCount;
  final int activeMembersCount;
  final List<CuisineItemMappingModel> items;

  factory CuisineModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((e) => CuisineItemMappingModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return CuisineModel(
      id: (json['id'] ?? '').toString(),
      cuisineName: (json['cuisine_name'] ?? json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      mappedItemsCount: (json['mapped_items_count'] as num?)?.toInt() ?? itemsList.length,
      activeMembersCount: (json['active_members_count'] as num?)?.toInt() ?? 0,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cuisine_name': cuisineName,
        'description': description,
        'is_active': isActive ? 1 : 0,
        'mapped_items_count': mappedItemsCount,
        'active_members_count': activeMembersCount,
        'items': items.map((e) => e.toJson()).toList(),
      };

  Cuisine toEntity() => Cuisine(
        id: id,
        cuisineName: cuisineName,
        description: description,
        isActive: isActive,
        mappedItemsCount: mappedItemsCount,
        activeMembersCount: activeMembersCount,
        items: items.map((e) => e.toEntity()).toList(),
      );
}

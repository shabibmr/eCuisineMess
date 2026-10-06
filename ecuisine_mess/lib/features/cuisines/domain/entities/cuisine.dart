import 'package:ecuisine_mess/features/cuisines/domain/entities/cuisine_item_mapping.dart';
import 'package:equatable/equatable.dart';

class Cuisine extends Equatable {
  const Cuisine({
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
  final List<CuisineItemMapping> items;

  Cuisine copyWith({
    String? id,
    String? cuisineName,
    String? description,
    bool? isActive,
    int? mappedItemsCount,
    int? activeMembersCount,
    List<CuisineItemMapping>? items,
  }) {
    return Cuisine(
      id: id ?? this.id,
      cuisineName: cuisineName ?? this.cuisineName,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      mappedItemsCount: mappedItemsCount ?? this.mappedItemsCount,
      activeMembersCount: activeMembersCount ?? this.activeMembersCount,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        cuisineName,
        description,
        isActive,
        mappedItemsCount,
        activeMembersCount,
        items,
      ];
}

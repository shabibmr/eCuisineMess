import 'package:ecuisine_mess/features/items/domain/entities/uom.dart';

class UomModel {
  const UomModel({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  factory UomModel.fromJson(Map<String, dynamic> json) {
    return UomModel(
      id: json['id']?.toString() ?? '',
      name: json['uom_name']?.toString() ?? '',
      sortOrder: json['sort_order'] is int
          ? json['sort_order'] as int
          : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Uom toEntity() => Uom(
        id: id,
        name: name,
        sortOrder: sortOrder,
        isActive: isActive,
      );
}

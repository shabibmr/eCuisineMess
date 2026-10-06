import 'package:ecuisine_mess/features/members/domain/entities/cuisine_option.dart';

class CuisineOptionModel {
  const CuisineOptionModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final String id;
  final String name;
  final bool isActive;

  factory CuisineOptionModel.fromJson(Map<String, dynamic> json) {
    return CuisineOptionModel(
      id: json['id']?.toString() ?? '',
      name: json['cuisine_name']?.toString() ??
          json['name']?.toString() ??
          '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  CuisineOption toEntity() => CuisineOption(
        id: id,
        name: name,
        isActive: isActive,
      );
}

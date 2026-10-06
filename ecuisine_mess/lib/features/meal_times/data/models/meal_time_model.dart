import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';

class MealTimeModel {
  const MealTimeModel({
    required this.id,
    required this.cuisineId,
    this.cuisineName,
    required this.mealType,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  final String id;
  final String cuisineId;
  final String? cuisineName;
  final String mealType;
  final String name;
  final String startTime;
  final String endTime;
  final bool isActive;

  factory MealTimeModel.fromJson(Map<String, dynamic> json) {
    return MealTimeModel(
      id: json['id']?.toString() ?? '',
      cuisineId: json['cuisine_id']?.toString() ?? '',
      cuisineName: json['cuisine_name']?.toString(),
      mealType: json['meal_type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      isActive: _asBool(json['is_active']),
    );
  }

  MealTime toEntity() => MealTime(
        id: id,
        cuisineId: cuisineId,
        cuisineName: cuisineName,
        mealType: mealType,
        name: name,
        startTime: startTime,
        endTime: endTime,
        isActive: isActive,
      );

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is int) return value != 0;
    final s = value?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }
}

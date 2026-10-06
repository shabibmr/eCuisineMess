import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';

class MealWindowModel {
  const MealWindowModel({
    required this.name,
    required this.mealType,
    required this.startTime,
    required this.endTime,
  });

  final String name;
  final String mealType;
  final String startTime;
  final String endTime;

  factory MealWindowModel.fromJson(Map<String, dynamic> json) {
    return MealWindowModel(
      name: json['name']?.toString() ?? '',
      mealType: json['meal_type']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
    );
  }

  MealWindow toEntity() => MealWindow(
        name: name,
        mealType: mealType,
        startTime: startTime,
        endTime: endTime,
      );
}

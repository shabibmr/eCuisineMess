import 'package:equatable/equatable.dart';

class MealTime extends Equatable {
  const MealTime({
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

  @override
  List<Object?> get props => [
        id,
        cuisineId,
        cuisineName,
        mealType,
        name,
        startTime,
        endTime,
        isActive,
      ];
}

import 'package:equatable/equatable.dart';

class MealWindow extends Equatable {
  const MealWindow({
    required this.name,
    required this.mealType,
    required this.startTime,
    required this.endTime,
  });

  final String name;
  final String mealType;
  final String startTime;
  final String endTime;

  @override
  List<Object?> get props => [name, mealType, startTime, endTime];
}

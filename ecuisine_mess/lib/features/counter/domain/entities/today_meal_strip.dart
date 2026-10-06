import 'package:equatable/equatable.dart';

/// Served status for B / L / D today (`today` from tap API).
class TodayMealStrip extends Equatable {
  const TodayMealStrip({
    this.breakfast = false,
    this.lunch = false,
    this.dinner = false,
  });

  final bool breakfast;
  final bool lunch;
  final bool dinner;

  static const empty = TodayMealStrip();

  @override
  List<Object?> get props => [breakfast, lunch, dinner];
}

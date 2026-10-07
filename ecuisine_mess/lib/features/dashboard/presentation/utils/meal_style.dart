import 'package:flutter/material.dart';

/// Display metadata for a meal type; the UI never shows raw `B/L/D` codes
/// outside compact table headers.
class MealStyle {
  const MealStyle(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;

  static const breakfast = MealStyle(
    'Breakfast',
    Color(0xFFF59E0B),
    Icons.wb_twilight,
  );
  static const lunch = MealStyle(
    'Lunch',
    Color(0xFF10B981),
    Icons.wb_sunny_outlined,
  );
  static const dinner = MealStyle(
    'Dinner',
    Color(0xFF6366F1),
    Icons.nights_stay_outlined,
  );

  static const all = [breakfast, lunch, dinner];

  static MealStyle of(String mealType) {
    switch (mealType.toUpperCase()) {
      case 'BREAKFAST':
        return breakfast;
      case 'LUNCH':
        return lunch;
      case 'DINNER':
        return dinner;
    }
    return MealStyle(mealType, Colors.blueGrey, Icons.restaurant);
  }
}

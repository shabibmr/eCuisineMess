import 'package:ecuisine_mess/features/counter/domain/entities/today_meal_strip.dart';
import 'package:flutter/material.dart';

class TodayStrip extends StatelessWidget {
  const TodayStrip({super.key, required this.strip});

  final TodayMealStrip strip;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _chip('B', strip.breakfast),
        _chip('L', strip.lunch),
        _chip('D', strip.dinner),
      ],
    );
  }

  Widget _chip(String label, bool served) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: served ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: served ? Colors.green.shade400 : Colors.grey.shade400,
        ),
      ),
      child: Text(
        '$label ${served ? '✔' : '—'}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: served ? Colors.green.shade800 : Colors.black54,
        ),
      ),
    );
  }
}

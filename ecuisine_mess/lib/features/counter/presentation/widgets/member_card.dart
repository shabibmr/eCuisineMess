import 'package:ecuisine_mess/features/counter/domain/entities/counter_member_snapshot.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/today_meal_strip.dart';
import 'package:ecuisine_mess/features/counter/presentation/widgets/today_strip.dart';
import 'package:flutter/material.dart';

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    this.today = TodayMealStrip.empty,
    this.isOverride = false,
  });

  final CounterMemberSnapshot member;
  final TodayMealStrip today;
  final bool isOverride;

  @override
  Widget build(BuildContext context) {
    final initial =
        member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : 'M';

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOverride) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: const Text('OVERRIDE'),
                      backgroundColor: Colors.orange.shade100,
                      labelStyle: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ],
              ),
              Text(
                'Phone: ${member.phone ?? 'N/A'}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TodayStrip(strip: today),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Cuisine: ${member.cuisineName ?? '—'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              Text(
                'Validity: ${member.daysLeft ?? 0} days left',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

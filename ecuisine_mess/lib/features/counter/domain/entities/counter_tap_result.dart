import 'package:ecuisine_mess/features/counter/domain/entities/counter_line_item.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/counter_member_snapshot.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/today_meal_strip.dart';
import 'package:equatable/equatable.dart';

class ExistingBillRef extends Equatable {
  const ExistingBillRef({
    this.id,
    this.billNumber,
    this.tokenNumber,
    this.billTime,
  });

  final String? id;
  final String? billNumber;
  final String? tokenNumber;
  final String? billTime;

  @override
  List<Object?> get props => [id, billNumber, tokenNumber, billTime];
}

class CounterTapResult extends Equatable {
  const CounterTapResult({
    required this.success,
    this.errorCode,
    this.message,
    this.member,
    this.mealType,
    this.items = const [],
    this.totalAmount = 0,
    this.existingBill,
    this.today = TodayMealStrip.empty,
  });

  final bool success;
  final String? errorCode;
  final String? message;
  final CounterMemberSnapshot? member;
  final String? mealType;
  final List<CounterLineItem> items;
  final double totalAmount;
  final ExistingBillRef? existingBill;
  final TodayMealStrip today;

  bool get canOverride =>
      errorCode == 'ALREADY_SERVED' || errorCode == 'EXPIRED';

  @override
  List<Object?> get props => [
        success,
        errorCode,
        message,
        member,
        mealType,
        items,
        totalAmount,
        existingBill,
        today,
      ];
}

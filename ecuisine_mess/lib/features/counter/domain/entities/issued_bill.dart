import 'package:ecuisine_mess/features/counter/domain/entities/counter_line_item.dart';
import 'package:ecuisine_mess/shared/models/token_slip_data.dart';
import 'package:equatable/equatable.dart';

class IssuedBill extends Equatable {
  const IssuedBill({
    this.id,
    this.billNumber,
    required this.tokenNumber,
    required this.date,
    required this.time,
    required this.memberName,
    required this.cuisine,
    required this.mealType,
    this.items = const [],
    this.totalAmount = 0,
    this.isOverride = false,
  });

  final String? id;
  final String? billNumber;
  final String tokenNumber;
  final String date;
  final String time;
  final String memberName;
  final String cuisine;
  final String mealType;
  final List<CounterLineItem> items;
  final double totalAmount;
  final bool isOverride;

  TokenSlipData toSlipData() => TokenSlipData(
        tokenNumber: tokenNumber,
        memberName: memberName,
        cuisine: cuisine,
        mealType: mealType,
        date: date,
        time: time,
        items: items
            .map(
              (e) => TokenSlipLine(name: e.name, quantity: e.quantity),
            )
            .toList(),
      );

  String get summary => '$tokenNumber · $memberName · $mealType';

  @override
  List<Object?> get props => [
        id,
        billNumber,
        tokenNumber,
        date,
        time,
        memberName,
        cuisine,
        mealType,
        items,
        totalAmount,
        isOverride,
      ];
}

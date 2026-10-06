import 'package:ecuisine_mess/shared/models/token_slip_data.dart';
import 'package:equatable/equatable.dart';

class BillLine extends Equatable {
  const BillLine({
    this.itemId,
    required this.name,
    this.quantity = 1,
    this.unitPrice = 0,
    this.totalPrice = 0,
  });

  final String? itemId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  @override
  List<Object?> get props => [itemId, name, quantity, unitPrice, totalPrice];
}

class Bill extends Equatable {
  const Bill({
    required this.id,
    required this.billNumber,
    required this.tokenNumber,
    required this.billDate,
    required this.billTime,
    required this.memberName,
    required this.cuisineName,
    required this.mealType,
    this.totalAmount = 0,
    required this.status,
    this.isOverride = false,
    this.overrideBy,
    this.overrideReason,
    this.items = const [],
  });

  final String id;
  final String billNumber;
  final String tokenNumber;
  final String billDate;
  final String billTime;
  final String memberName;
  final String cuisineName;
  final String mealType;
  final double totalAmount;
  final String status;
  final bool isOverride;
  final String? overrideBy;
  final String? overrideReason;
  final List<BillLine> items;

  bool get isCancelled => status == 'CANCELLED';

  TokenSlipData toSlipData() => TokenSlipData(
        tokenNumber: tokenNumber,
        memberName: memberName,
        cuisine: cuisineName,
        mealType: mealType,
        date: billDate,
        time: billTime,
        items: items
            .map((e) => TokenSlipLine(name: e.name, quantity: e.quantity))
            .toList(),
      );

  @override
  List<Object?> get props => [
        id,
        billNumber,
        tokenNumber,
        billDate,
        billTime,
        memberName,
        cuisineName,
        mealType,
        totalAmount,
        status,
        isOverride,
        overrideBy,
        overrideReason,
        items,
      ];
}

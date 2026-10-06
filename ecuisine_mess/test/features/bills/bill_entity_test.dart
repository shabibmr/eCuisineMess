import 'package:ecuisine_mess/features/bills/data/models/bill_model.dart';
import 'package:ecuisine_mess/features/bills/domain/entities/bill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BillModel maps list JSON and slip data', () {
    final model = BillModel.fromJson({
      'id': 'b1',
      'bill_number': 'BL-1',
      'token_number': 'L-0001',
      'bill_date': '2026-10-05',
      'bill_time': '12:30:00',
      'member_name': 'Rahul',
      'cuisine_name': 'South Indian',
      'meal_type': 'LUNCH',
      'total_amount': 0,
      'status': 'SERVED',
      'is_override': 0,
      'items': [
        {'item_name': 'Rice', 'quantity': 1},
        {'name': 'Sambar', 'quantity': 2},
      ],
    });

    final Bill bill = model.toEntity();
    expect(bill.tokenNumber, 'L-0001');
    expect(bill.items, hasLength(2));
    expect(bill.items.first.name, 'Rice');

    final slip = bill.toSlipData();
    expect(slip.tokenNumber, 'L-0001');
    expect(slip.memberName, 'Rahul');
    expect(slip.items.first.name, 'Rice');
    expect(bill.isCancelled, isFalse);
  });
}

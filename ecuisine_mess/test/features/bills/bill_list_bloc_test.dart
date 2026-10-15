import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/bills/domain/usecases/cancel_bill.dart';
import 'package:ecuisine_mess/features/bills/domain/usecases/get_bill.dart';
import 'package:ecuisine_mess/features/bills/domain/usecases/get_bills.dart';
import 'package:ecuisine_mess/features/bills/presentation/bloc/bill_list_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetBills extends Mock implements GetBills {}

class _MockGetBill extends Mock implements GetBill {}

class _MockCancelBill extends Mock implements CancelBill {}

void main() {
  setUpAll(() {
    registerFallbackValue(const GetBillsParams());
  });

  test('loads bills for today by default', () async {
    final getBills = _MockGetBills();
    final today = BillListBloc.formatDate(DateTime.now());
    when(() => getBills(any())).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.single as GetBillsParams;
      expect(params.billDate, today);
      return [];
    });

    final bloc = BillListBloc(
      getBills: getBills,
      getBill: _MockGetBill(),
      cancelBill: _MockCancelBill(),
    );
    addTearDown(bloc.close);

    expect(bloc.state.billDate, today);
    bloc.add(const BillListStarted());
    await bloc.stream.firstWhere((state) => state.status == Status.success);
    verify(() => getBills(any())).called(1);
  });
}

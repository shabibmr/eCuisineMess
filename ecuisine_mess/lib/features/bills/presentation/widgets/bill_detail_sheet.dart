import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/bills/domain/entities/bill.dart';
import 'package:ecuisine_mess/features/bills/presentation/bloc/bill_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showBillDetailSheet(BuildContext context, String billId) {
  final bloc = context.read<BillListBloc>();
  bloc.add(BillDetailRequested(billId));
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return BlocProvider.value(
        value: bloc,
        child: const _BillDetailSheetBody(),
      );
    },
  ).whenComplete(() {
    bloc.add(const BillDetailCleared());
  });
}

class _BillDetailSheetBody extends StatelessWidget {
  const _BillDetailSheetBody();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return BlocBuilder<BillListBloc, BillListState>(
          builder: (context, state) {
            if (state.detailStatus == Status.loading ||
                state.detailStatus == Status.initial) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.detailStatus == Status.failure) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.detailError ?? 'Failed to load bill'),
              );
            }
            final bill = state.selectedBill;
            if (bill == null) {
              return const SizedBox.shrink();
            }
            return _BillVoucher(
              bill: bill,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class _BillVoucher extends StatelessWidget {
  const _BillVoucher({
    required this.bill,
    required this.scrollController,
  });

  final Bill bill;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text(
          bill.tokenNumber,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          bill.billNumber,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        if (bill.isCancelled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Chip(
              label: const Text('CANCELLED'),
              backgroundColor: Colors.red.shade50,
              labelStyle: TextStyle(color: Colors.red.shade800),
            ),
          ),
        const Divider(height: 28),
        _row('Member', bill.memberName),
        _row('Cuisine', bill.cuisineName),
        _row('Meal', bill.mealType),
        _row('Date', '${bill.billDate} ${bill.billTime}'),
        _row('Status', bill.status),
        if (bill.isOverride) _row('Override by', bill.overrideBy ?? '—'),
        if (bill.overrideReason != null && bill.overrideReason!.isNotEmpty)
          _row('Reason', bill.overrideReason!),
        const Divider(height: 28),
        const Text(
          'Line items',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (bill.items.isEmpty)
          const Text('No line items', style: TextStyle(color: Colors.black54))
        else
          ...bill.items.map(
            (line) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line.name),
              trailing: Text('× ${line.quantity.toStringAsFixed(0)}'),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

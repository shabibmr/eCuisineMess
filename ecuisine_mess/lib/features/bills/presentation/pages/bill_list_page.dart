import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/bills/domain/entities/bill.dart';
import 'package:ecuisine_mess/features/bills/presentation/bloc/bill_list_bloc.dart';
import 'package:ecuisine_mess/features/bills/presentation/widgets/bill_cancel_dialog.dart';
import 'package:ecuisine_mess/features/bills/presentation/widgets/bill_detail_sheet.dart';
import 'package:ecuisine_mess/features/bills/presentation/widgets/bill_filters_bar.dart';
import 'package:ecuisine_mess/shared/widgets/badges/app_status_badge.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_refresh_button.dart';
import 'package:ecuisine_mess/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:ecuisine_mess/shared/widgets/print/token_slip_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/tables/app_separated_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BillListPage extends StatelessWidget {
  const BillListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BillListBloc>()..add(const BillListStarted()),
      child: const _BillListView(),
    );
  }
}

class _BillListView extends StatefulWidget {
  const _BillListView();

  @override
  State<_BillListView> createState() => _BillListViewState();
}

class _BillListViewState extends State<_BillListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cancelBill(Bill bill) async {
    final proceed = await AppConfirmDialog.show(
      context: context,
      title: 'Cancel Bill ${bill.billNumber}?',
      message:
          'Cancelled vouchers are marked as CANCELLED and excluded from daily '
          'meal accounts. Continue to enter a cancellation reason?',
      confirmLabel: 'Continue',
      isDestructive: true,
    );
    if (!proceed || !mounted) return;

    final result = await showDialog<BillCancelResult>(
      context: context,
      builder: (_) => BillCancelDialog(billNumber: bill.billNumber),
    );
    if (result == null || !mounted) return;
    context.read<BillListBloc>().add(
          BillCancelRequested(
            id: bill.id,
            reason: result.reason,
            cancelledBy: result.cancelledBy,
          ),
        );
  }

  void _reprint(Bill bill) {
    showDialog<void>(
      context: context,
      builder: (_) => TokenSlipDialog(
        slip: bill.toSlipData(),
        isReprint: true,
      ),
    );
  }

  String _formatDate(DateTime picked) {
    return '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BillListBloc, BillListState>(
      listenWhen: (prev, next) =>
          next.notice != null ||
          (next.status == Status.failure &&
              next.error != null &&
              prev.status == Status.submitting),
      listener: (context, state) {
        if (state.notice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.notice!)),
          );
          context.read<BillListBloc>().add(const BillListNoticeConsumed());
        } else if (state.status == Status.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final loading =
            state.status == Status.loading || state.status == Status.initial;
        final showError = state.status == Status.failure &&
            state.bills.isEmpty &&
            state.error != null;

        return MasterPage(
          title: 'Bill & Token Register',
          subtitle:
              'Audit trail of all issued tokens, reprints and supervisor cancellations',
          loading: loading,
          error: showError ? state.error : null,
          onRetry: () =>
              context.read<BillListBloc>().add(const BillListRefreshed()),
          isEmpty: !loading && !showError && state.bills.isEmpty,
          emptyMessage: 'No bills found',
          actions: [
            AppRefreshButton(
              onPressed: () =>
                  context.read<BillListBloc>().add(const BillListRefreshed()),
            ),
          ],
          toolbar: BillFiltersBar(
            searchController: _searchController,
            onSearchChanged: (val) => context
                .read<BillListBloc>()
                .add(BillListFiltersChanged(search: val)),
            mealType: state.mealType,
            status: state.billStatus,
            billDate: state.billDate,
            onMealTypeChanged: (val) => context.read<BillListBloc>().add(
                  BillListFiltersChanged(
                    mealType: val,
                    clearMealType: val == null,
                  ),
                ),
            onStatusChanged: (val) => context.read<BillListBloc>().add(
                  BillListFiltersChanged(
                    billStatus: val,
                    clearBillStatus: val == null,
                  ),
                ),
            onDateChanged: (picked) => context.read<BillListBloc>().add(
                  BillListFiltersChanged(billDate: _formatDate(picked)),
                ),
            onClearDate: () => context.read<BillListBloc>().add(
                  const BillListFiltersChanged(clearBillDate: true),
                ),
          ),
          child: AppSeparatedListCard(
            itemCount: state.bills.length,
            itemBuilder: (context, index) {
              final b = state.bills[index];
              final isCancelled = b.isCancelled;
              return ListTile(
                onTap: () => showBillDetailSheet(context, b.id),
                leading: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? Colors.grey.shade200
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCancelled ? Colors.grey : Colors.blue.shade300,
                    ),
                  ),
                  child: Text(
                    b.tokenNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCancelled
                          ? Colors.grey.shade600
                          : Colors.blue.shade900,
                      decoration:
                          isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                title: Text(
                  '${b.memberName} • ${b.cuisineName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration:
                        isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  '${b.billNumber} • ${b.mealType} • ${b.billDate} ${b.billTime}'
                  '${b.isOverride ? ' • [OVERRIDE]' : ''}'
                  '${isCancelled ? ' • [CANCELLED: ${b.overrideReason ?? 'By supervisor'}]' : ''}',
                  style: TextStyle(
                    color: isCancelled ? Colors.red : Colors.black54,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCancelled)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: AppStatusBadge.cancelled(compact: true),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: AppStatusBadge.served(compact: true),
                      ),
                    IconButton(
                      icon: const Icon(Icons.print, size: 20),
                      tooltip: 'Reprint Token Slip',
                      onPressed: () => _reprint(b),
                    ),
                    if (!isCancelled)
                      IconButton(
                        icon: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: 'Cancel Bill',
                        onPressed: () => _cancelBill(b),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/shortcuts/counter_shortcuts.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/counter/presentation/bloc/counter_bloc.dart';
import 'package:ecuisine_mess/features/counter/presentation/cubit/meal_clock_cubit.dart';
import 'package:ecuisine_mess/features/counter/presentation/widgets/action_bar.dart';
import 'package:ecuisine_mess/features/counter/presentation/widgets/invoice_grid.dart';
import 'package:ecuisine_mess/features/counter/presentation/widgets/meal_banner.dart';
import 'package:ecuisine_mess/features/counter/presentation/widgets/member_card.dart';
import 'package:ecuisine_mess/features/counter/presentation/widgets/reject_banner.dart';
import 'package:ecuisine_mess/features/counter/presentation/widgets/rfid_input_bar.dart';
import 'package:ecuisine_mess/shared/widgets/counter/rfid_tap_simulator.dart';
import 'package:ecuisine_mess/shared/widgets/counter/supervisor_override_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/print/token_slip_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<CounterBloc>()..add(const CounterStarted()),
        ),
        BlocProvider(create: (_) => MealClockCubit()),
      ],
      child: const _CounterView(),
    );
  }
}

class _CounterView extends StatefulWidget {
  const _CounterView();

  @override
  State<_CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<_CounterView> {
  final _rfidController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refocus());
  }

  @override
  void dispose() {
    _rfidController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _refocus() {
    if (mounted) _focusNode.requestFocus();
  }

  void _onScan(String tag) {
    if (tag.trim().isEmpty) return;
    context.read<CounterBloc>().add(CounterRfidScanned(tag.trim()));
    _rfidController.clear();
    _refocus();
  }

  void _clear() {
    context.read<CounterBloc>().add(const CounterCleared());
    _rfidController.clear();
    _refocus();
  }

  Future<void> _openSupervisor() async {
    final bloc = context.read<CounterBloc>();
    final tap = bloc.state.tapResult;
    if (tap == null || !tap.canOverride) return;

    await showDialog<void>(
      context: context,
      builder: (_) => SupervisorOverrideDialog(
        onAuthorized: (supervisor, reason) {
          bloc.add(
            CounterSupervisorOverrideGranted(
              name: supervisor,
              reason: reason,
            ),
          );
        },
      ),
    );
    _refocus();
  }

  Future<void> _saveAndPrint() async {
    final bloc = context.read<CounterBloc>();
    if (!bloc.state.canIssue) return;
    bloc.add(const CounterIssueTokenRequested());
  }

  Future<void> _onIssued(IssuedSlipReady slip) async {
    await showDialog<void>(
      context: context,
      builder: (_) => TokenSlipDialog(slip: slip.data),
    );
    if (!mounted) return;
    context.read<CounterBloc>().add(const CounterCleared());
    _rfidController.clear();
    _refocus();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: counterCallbackBindings(
        onSavePrint: _saveAndPrint,
        onSupervisorOverride: _openSupervisor,
        onClear: _clear,
        onExit: () => context.go(AppRoutes.members.path),
      ),
      child: Focus(
        autofocus: true,
        child: BlocConsumer<CounterBloc, CounterState>(
          listenWhen: (prev, next) =>
              next.lastIssuedBill != null &&
              next.lastIssuedBill != prev.lastIssuedBill,
          listener: (context, state) {
            final bill = state.lastIssuedBill;
            if (bill != null) {
              _onIssued(IssuedSlipReady(bill.toSlipData()));
            }
          },
          builder: (context, state) {
            final tap = state.tapResult;
            final showReject = state.error != null && !state.showInvoice;
            final busy = state.status == Status.loading ||
                state.status == Status.submitting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MealBanner(mealWindow: state.mealWindow),
                  const SizedBox(height: 16),
                  RfidTapSimulator(onScan: _onScan),
                  const SizedBox(height: 16),
                  RfidInputBar(
                    controller: _rfidController,
                    focusNode: _focusNode,
                    onSubmit: _onScan,
                    onClear: _clear,
                  ),
                  if (busy) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(minHeight: 3),
                  ],
                  const SizedBox(height: 20),
                  if (showReject)
                    RejectBanner(
                      message: state.error!,
                      showOverride: tap?.canOverride == true,
                      onOverride: _openSupervisor,
                    ),
                  if (state.showInvoice && tap?.member != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MemberCard(
                              member: tap!.member!,
                              today: tap.today,
                              isOverride: state.isOverride,
                            ),
                            const Divider(height: 32),
                            InvoiceGrid(
                              items: tap.items,
                              mealType: tap.mealType ??
                                  state.mealWindow?.mealType ??
                                  'LUNCH',
                            ),
                            const Divider(height: 32),
                            CounterActionBar(
                              onSavePrint: _saveAndPrint,
                              onClear: _clear,
                              onSupervisor: _openSupervisor,
                              lastTokenSummary: state.lastTokenSummary,
                              busy: state.status == Status.submitting,
                              canSave: state.canIssue,
                              canOverride: tap.canOverride && !state.isOverride,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!state.showInvoice && state.lastTokenSummary != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Last token: ${state.lastTokenSummary}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class IssuedSlipReady {
  const IssuedSlipReady(this.data);
  final TokenSlipData data;
}

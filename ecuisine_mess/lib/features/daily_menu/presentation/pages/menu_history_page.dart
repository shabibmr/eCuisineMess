import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/router/app_routes.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/bloc/menu_history_bloc.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/widgets/menu_history_copy_dialog.dart';
import 'package:ecuisine_mess/features/daily_menu/presentation/widgets/menu_history_details_dialog.dart';
import 'package:ecuisine_mess/shared/widgets/feedback/error_banner.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MenuHistoryPage extends StatelessWidget {
  const MenuHistoryPage({
    super.key,
    this.fromDate,
    this.toDate,
    this.cuisineId,
  });

  final String? fromDate;
  final String? toDate;
  final String? cuisineId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MenuHistoryBloc>()
        ..add(
          MenuHistoryStarted(
            fromDate: fromDate,
            toDate: toDate,
            cuisineId: cuisineId,
          ),
        ),
      child: const _MenuHistoryView(),
    );
  }
}

class _MenuHistoryView extends StatefulWidget {
  const _MenuHistoryView();

  @override
  State<_MenuHistoryView> createState() => _MenuHistoryViewState();
}

class _MenuHistoryViewState extends State<_MenuHistoryView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required BuildContext context,
    required bool isFrom,
    required String currentDate,
  }) async {
    final parts = currentDate.split('-');
    DateTime initial = DateTime.now();
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) {
        initial = DateTime(y, m, d);
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked == null || !context.mounted) return;

    final formatted = MenuHistoryBloc.formatDate(picked);
    final bloc = context.read<MenuHistoryBloc>();
    final state = bloc.state;

    if (isFrom) {
      bloc.add(MenuHistoryDateRangeChanged(fromDate: formatted, toDate: state.toDate));
    } else {
      bloc.add(MenuHistoryDateRangeChanged(fromDate: state.fromDate, toDate: formatted));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuHistoryBloc, MenuHistoryState>(
      builder: (context, state) {
        final records = state.filteredRecords;
        final loading = state.status == Status.loading && state.records.isEmpty;

        return MasterPage(
          title: 'Daily Menu History',
          subtitle: 'Archive of past daily menus across all cuisines',
          loading: loading,
          error: state.status == Status.failure && state.records.isEmpty ? state.error : null,
          onRetry: () => context.read<MenuHistoryBloc>().add(const MenuHistoryRefreshRequested()),
          actions: [
            FilledButton.icon(
              icon: const Icon(Icons.restaurant_menu, size: 16),
              label: const Text('Open Menu Editor'),
              onPressed: () => context.goNamed(AppRoutes.menu.name),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search cuisine or date...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      context.read<MenuHistoryBloc>().add(const MenuHistorySearchChanged(''));
                                    },
                                  )
                                : null,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            context.read<MenuHistoryBloc>().add(MenuHistorySearchChanged(v));
                          },
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('From:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(state.fromDate.isEmpty ? 'Start' : state.fromDate),
                            onPressed: () => _pickDate(
                              context: context,
                              isFrom: true,
                              currentDate: state.fromDate,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('To:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(state.toDate.isEmpty ? 'End' : state.toDate),
                            onPressed: () => _pickDate(
                              context: context,
                              isFrom: false,
                              currentDate: state.toDate,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Cuisine:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          DropdownButton<String?>(
                            value: state.selectedCuisineId,
                            hint: const Text('All Cuisines'),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Cuisines'),
                              ),
                              for (final c in state.cuisines)
                                DropdownMenuItem<String?>(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                            ],
                            onChanged: (v) {
                              context.read<MenuHistoryBloc>().add(MenuHistoryCuisineFiltered(v));
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                        onPressed: () => context.read<MenuHistoryBloc>().add(const MenuHistoryRefreshRequested()),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.status == Status.failure && state.records.isNotEmpty && state.error != null) ...[
                const SizedBox(height: 8),
                ErrorBanner(message: state.error!),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  margin: EdgeInsets.zero,
                  child: records.isEmpty
                      ? Center(
                          child: Text(
                            state.status == Status.loading ? 'Loading menu history...' : 'No menu history records found.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : SingleChildScrollView(
                          child: DataTable(
                            headingRowHeight: 44,
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 56,
                            columns: const [
                              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Cuisine', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Breakfast', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Lunch', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Dinner', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: [
                              for (final rec in records)
                                DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        rec.date,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(rec.cuisineName, style: const TextStyle(fontWeight: FontWeight.w500)),
                                          if (rec.isLocked) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.lock, size: 14, color: Colors.grey),
                                          ],
                                        ],
                                      ),
                                    ),
                                    DataCell(_MealBadge(count: rec.breakfastCount, color: Colors.amber.shade700)),
                                    DataCell(_MealBadge(count: rec.lunchCount, color: Colors.teal.shade700)),
                                    DataCell(_MealBadge(count: rec.dinnerCount, color: Colors.indigo.shade700)),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.visibility_outlined, size: 18),
                                            tooltip: 'View details',
                                            onPressed: () => MenuHistoryDetailsDialog.show(context, rec),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy_outlined, size: 18),
                                            tooltip: 'Copy to date',
                                            onPressed: () => MenuHistoryCopyDialog.show(context, sourceRecord: rec),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            tooltip: 'Open in Editor',
                                            onPressed: () => context.goNamed(
                                              AppRoutes.menu.name,
                                              queryParameters: {
                                                'date': rec.date,
                                                'cuisine_id': rec.cuisineId,
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                child: Text(
                  '${records.length} menu records archived',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MealBadge extends StatelessWidget {
  const _MealBadge({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Text('Empty', style: TextStyle(color: Colors.grey, fontSize: 12));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$count items',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

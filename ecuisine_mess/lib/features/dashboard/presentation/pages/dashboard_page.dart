import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/utils/meal_timeline_logic.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/widgets/meal_timeline.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/widgets/menu_readiness_grid.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/widgets/served_by_cuisine_table.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/widgets/served_kpi_row.dart';
import 'package:ecuisine_mess/shared/cubit/meal_clock_cubit.dart';
import 'package:ecuisine_mess/shared/widgets/feedback/error_banner.dart';
import 'package:ecuisine_mess/shared/widgets/layout/master_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<DashboardBloc>()..add(const DashboardStarted()),
        ),
        BlocProvider(create: (_) => MealClockCubit()),
      ],
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  /// Below this width the readiness grid and served table stack vertically.
  static const stackBreakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final summary = state.summary;
        final loading =
            state.status == Status.initial || state.status == Status.loading;
        final failed = state.status == Status.failure;
        final day = summary?.serverTime ?? DateTime.now();

        return MasterPage(
          title: "Today's Operations",
          subtitle: DateFormat('EEEE, d MMMM yyyy').format(day),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: state.refreshing || loading
                  ? null
                  : () => context.read<DashboardBloc>().add(
                      const DashboardRefreshRequested(),
                    ),
              icon: state.refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
          toolbar: summary == null
              ? null
              : DashboardHeader(currentMealName: summary.currentWindow?.name),
          loading: loading,
          error: failed ? state.error : null,
          onRetry: () =>
              context.read<DashboardBloc>().add(const DashboardStarted()),
          child: summary == null
              ? const SizedBox.shrink()
              : _Content(state: state, summary: summary, day: day),
        );
      },
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.summary,
    required this.day,
  });

  final DashboardState state;
  final DashboardSummary summary;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final windows = buildTimelineWindows(
      state.mealTimes,
      fallback: [summary.currentWindow, summary.nextWindow],
    );
    final menuDate = DateFormat('yyyy-MM-dd').format(day);

    final readiness = MenuReadinessGrid(
      rows: summary.menuReadiness,
      menuDate: menuDate,
    );
    final served = ServedByCuisineTable(rows: summary.servedByCuisine);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.refreshError != null) ...[
            ErrorBanner(
              message:
                  'Could not refresh: ${state.refreshError}. '
                  'Showing last data.',
              onRetry: () => context.read<DashboardBloc>().add(
                const DashboardRefreshRequested(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MealTimeline(windows: windows),
            ),
          ),
          const SizedBox(height: 12),
          ServedKpiRow(served: summary.servedToday),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < DashboardView.stackBreakpoint) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [readiness, const SizedBox(height: 12), served],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: readiness),
                  const SizedBox(width: 12),
                  Expanded(child: served),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/features/cuisines/domain/usecases/get_cuisines.dart';
import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/domain/usecases/reports_usecases.dart';
import 'package:ecuisine_mess/features/reports/presentation/cubit/report_cubit.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/attendance_tab.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/item_movement_tab.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/members_register_tab.dart';
import 'package:ecuisine_mess/features/reports/presentation/widgets/time_distribution_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ReportCubit<AttendanceReport>(
            kind: ReportKind.attendance,
            load: sl<GetAttendanceReport>(),
            export: sl(),
          ),
        ),
        BlocProvider(
          create: (_) => ReportCubit<List<ItemMovementRow>>(
            kind: ReportKind.itemMovement,
            load: sl<GetItemMovementReport>(),
            export: sl(),
          ),
        ),
        BlocProvider(
          create: (_) => ReportCubit<TimeDistributionReport>(
            kind: ReportKind.timeDistribution,
            load: sl<GetTimeDistributionReport>(),
            export: sl(),
          ),
        ),
        BlocProvider(
          create: (_) => ReportCubit<MembersRegister>(
            kind: ReportKind.members,
            load: sl<GetMembersRegister>(),
            export: sl(),
          ),
        ),
      ],
      child: const ReportsView(),
    );
  }
}

class ReportsView extends StatefulWidget {
  const ReportsView({super.key, this.loadCuisines});

  /// Overridable for tests; defaults to the cuisines use case.
  final Future<Map<String, String>> Function()? loadCuisines;

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  Map<String, String> _cuisines = const {};

  @override
  void initState() {
    super.initState();
    _loadCuisines();
  }

  Future<void> _loadCuisines() async {
    try {
      final loader = widget.loadCuisines ?? _defaultLoader;
      final cuisines = await loader();
      if (mounted) setState(() => _cuisines = cuisines);
    } catch (_) {
      // Reports still work unfiltered by cuisine.
    }
  }

  static Future<Map<String, String>> _defaultLoader() async {
    final list = await sl<GetCuisines>()(
      const GetCuisinesParams(includeInactive: true),
    );
    return {for (final c in list) c.id: c.cuisineName};
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reports',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Attendance, item movement, counter traffic and member register',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(icon: Icon(Icons.event_note), text: 'Attendance'),
                Tab(icon: Icon(Icons.restaurant), text: 'Item Movement'),
                Tab(icon: Icon(Icons.schedule), text: 'Time Distribution'),
                Tab(icon: Icon(Icons.badge_outlined), text: 'Members Register'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                // Pickers are stateful; keep the filters when switching tabs.
                children: [
                  _Keep(AttendanceTab(cuisines: _cuisines)),
                  _Keep(ItemMovementTab(cuisines: _cuisines)),
                  _Keep(TimeDistributionTab(cuisines: _cuisines)),
                  _Keep(MembersRegisterTab(cuisines: _cuisines)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Keep extends StatefulWidget {
  const _Keep(this.child);

  final Widget child;

  @override
  State<_Keep> createState() => _KeepState();
}

class _KeepState extends State<_Keep> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

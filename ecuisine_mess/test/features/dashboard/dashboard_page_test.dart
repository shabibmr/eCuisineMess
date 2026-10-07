import 'package:bloc_test/bloc_test.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/counter/domain/entities/meal_window.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';
import 'package:ecuisine_mess/shared/cubit/meal_clock_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _MockBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class _FakeClock extends Cubit<String> implements MealClockCubit {
  _FakeClock(super.initial);
}

const _lunch = MealTime(
  id: '1',
  cuisineId: 'c1',
  mealType: 'LUNCH',
  name: 'Lunch',
  startTime: '12:00:00',
  endTime: '15:00:00',
);

const _summary = DashboardSummary(
  serverTime: null,
  currentMeal: 'LUNCH',
  currentWindow: MealWindow(
    name: 'Lunch',
    mealType: 'LUNCH',
    startTime: '12:00:00',
    endTime: '15:00:00',
  ),
  servedToday: ServedToday(breakfast: 4, lunch: 9, dinner: 0, total: 13),
  menuReadiness: [
    MenuReadiness(
      cuisineId: 'c1',
      cuisineName: 'North Indian',
      status: ReadinessStatus.partial,
      filledCount: 2,
      totalSlots: 3,
      breakfast: true,
      lunch: true,
      dinner: false,
    ),
  ],
  servedByCuisine: [
    ServedByCuisine(
      cuisineId: 'c1',
      cuisineName: 'North Indian',
      breakfast: 4,
      lunch: 9,
      dinner: 0,
      total: 13,
    ),
  ],
);

void main() {
  late _MockBloc bloc;
  String? lastLocation;

  setUp(() {
    bloc = _MockBloc();
    lastLocation = null;
  });

  Future<void> pump(
    WidgetTester tester,
    DashboardState state, {
    String clock = '13:00:00',
    Size size = const Size(1200, 900),
  }) async {
    whenListen(bloc, const Stream<DashboardState>.empty(), initialState: state);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<DashboardBloc>.value(value: bloc),
                BlocProvider<MealClockCubit>.value(value: _FakeClock(clock)),
              ],
              child: const DashboardView(),
            ),
          ),
        ),
        GoRoute(
          path: '/menu',
          builder: (_, s) {
            lastLocation = s.uri.toString();
            return const Scaffold(body: Text('menu editor'));
          },
        ),
        GoRoute(
          path: '/counter',
          builder: (_, _) => const Scaffold(body: Text('counter')),
        ),
        GoRoute(
          path: '/reports',
          builder: (_, _) => const Scaffold(body: Text('reports')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
  }

  testWidgets('loading', (tester) async {
    await pump(tester, const DashboardState(status: Status.loading));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('error with retry', (tester) async {
    await pump(
      tester,
      const DashboardState(status: Status.failure, error: 'Server unreachable'),
    );
    expect(find.text('Server unreachable'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    verify(() => bloc.add(const DashboardStarted())).called(1);
  });

  testWidgets('success shows header, timeline, KPIs, tables', (tester) async {
    await pump(
      tester,
      const DashboardState(
        status: Status.success,
        summary: _summary,
        mealTimes: [_lunch],
      ),
    );
    expect(find.text("Today's Operations"), findsOneWidget);
    expect(find.text('Current service: Lunch'), findsOneWidget);
    expect(find.text('Active: Lunch (until 15:00)'), findsOneWidget);
    expect(find.byKey(const ValueKey('timeline-now-marker')), findsOneWidget);
    expect(find.text('13'), findsWidgets); // total tile + table totals
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('Report ↗'), findsOneWidget);
  });

  testWidgets('Service Closed outside every window', (tester) async {
    await pump(
      tester,
      const DashboardState(
        status: Status.success,
        summary: DashboardSummary(
          servedToday: ServedToday.zero,
          menuReadiness: [],
          servedByCuisine: [],
        ),
        mealTimes: [_lunch],
      ),
      clock: '23:00:00',
    );
    expect(find.text('Service Closed'), findsOneWidget);
    expect(find.text('Service closed'), findsOneWidget);
    expect(find.text('No active cuisines'), findsNWidgets(2));
  });

  testWidgets('refresh failure keeps data and shows banner', (tester) async {
    await pump(
      tester,
      const DashboardState(
        status: Status.success,
        summary: _summary,
        mealTimes: [_lunch],
        refreshError: 'offline',
      ),
    );
    expect(find.textContaining('Could not refresh: offline'), findsOneWidget);
    expect(find.text('North Indian'), findsWidgets);
  });

  testWidgets('readiness cell opens the menu editor on that slot',
      (tester) async {
    await pump(
      tester,
      const DashboardState(
        status: Status.success,
        summary: _summary,
        mealTimes: [_lunch],
      ),
    );
    await tester.tap(find.byKey(const ValueKey('readiness-c1-DINNER')));
    await tester.pumpAndSettle();
    final uri = Uri.parse(lastLocation!);
    expect(uri.path, '/menu');
    expect(uri.queryParameters['cuisine_id'], 'c1');
    expect(uri.queryParameters['meal'], 'DINNER');
    expect(uri.queryParameters['date'], matches(r'^\d{4}-\d{2}-\d{2}$'));
  });

  testWidgets('narrow width stacks without overflow', (tester) async {
    await pump(
      tester,
      const DashboardState(
        status: Status.success,
        summary: _summary,
        mealTimes: [_lunch],
      ),
      size: const Size(600, 900),
    );
    expect(tester.takeException(), isNull);
    expect(find.text("Today's menu readiness"), findsOneWidget);
  });
}

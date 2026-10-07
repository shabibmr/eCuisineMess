import 'package:bloc_test/bloc_test.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/usecase/usecase.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/domain/usecases/get_dashboard_summary.dart';
import 'package:ecuisine_mess/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:ecuisine_mess/features/meal_times/domain/entities/meal_time.dart';
import 'package:ecuisine_mess/features/meal_times/domain/usecases/get_meal_times.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSummary extends Mock implements GetDashboardSummary {}

class _MockMealTimes extends Mock implements GetMealTimes {}

void main() {
  const summary = DashboardSummary(
    servedToday: ServedToday(breakfast: 1, lunch: 2, dinner: 3, total: 6),
    menuReadiness: [],
    servedByCuisine: [],
  );
  const updated = DashboardSummary(
    servedToday: ServedToday(breakfast: 2, lunch: 2, dinner: 3, total: 7),
    menuReadiness: [],
    servedByCuisine: [],
  );
  const active = MealTime(
    id: '1',
    cuisineId: 'c',
    mealType: 'LUNCH',
    name: 'Lunch',
    startTime: '12:00',
    endTime: '15:00',
  );
  const inactive = MealTime(
    id: '2',
    cuisineId: 'c',
    mealType: 'DINNER',
    name: 'Dinner',
    startTime: '19:00',
    endTime: '22:00',
    isActive: false,
  );

  late _MockSummary getSummary;
  late _MockMealTimes getMealTimes;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const GetMealTimesParams());
  });

  setUp(() {
    getSummary = _MockSummary();
    getMealTimes = _MockMealTimes();
    when(() => getMealTimes(any())).thenAnswer((_) async => [active, inactive]);
  });

  DashboardBloc build() => DashboardBloc(
    getDashboardSummary: getSummary,
    getMealTimes: getMealTimes,
    refreshInterval: Duration.zero,
  );

  blocTest<DashboardBloc, DashboardState>(
    'start success: loads summary and active meal times only',
    build: () {
      when(() => getSummary(any())).thenAnswer((_) async => summary);
      return build();
    },
    act: (b) => b.add(const DashboardStarted()),
    expect: () => [
      const DashboardState(status: Status.loading),
      const DashboardState(
        status: Status.success,
        summary: summary,
        mealTimes: [active],
      ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'start failure: no data, shows error',
    build: () {
      when(() => getSummary(any())).thenThrow(const NetworkFailure('down'));
      return build();
    },
    act: (b) => b.add(const DashboardStarted()),
    expect: () => [
      const DashboardState(status: Status.loading),
      const DashboardState(status: Status.failure, error: 'down'),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'meal-times failure does not fail the dashboard',
    build: () {
      when(() => getSummary(any())).thenAnswer((_) async => summary);
      when(() => getMealTimes(any())).thenThrow(const NetworkFailure('x'));
      return build();
    },
    act: (b) => b.add(const DashboardStarted()),
    expect: () => [
      const DashboardState(status: Status.loading),
      const DashboardState(status: Status.success, summary: summary),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'refresh success replaces data',
    build: () {
      var calls = 0;
      when(
        () => getSummary(any()),
      ).thenAnswer((_) async => ++calls == 1 ? summary : updated);
      return build();
    },
    act: (b) async {
      b.add(const DashboardStarted());
      await Future<void>.delayed(Duration.zero);
      b.add(const DashboardRefreshRequested());
    },
    skip: 2,
    expect: () => [
      const DashboardState(
        status: Status.success,
        summary: summary,
        mealTimes: [active],
        refreshing: true,
      ),
      const DashboardState(
        status: Status.success,
        summary: updated,
        mealTimes: [active],
      ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'refresh failure keeps last data and sets refreshError',
    build: () {
      var calls = 0;
      when(() => getSummary(any())).thenAnswer((_) async {
        if (++calls == 1) return summary;
        throw const NetworkFailure('offline');
      });
      return build();
    },
    act: (b) async {
      b.add(const DashboardStarted());
      await Future<void>.delayed(Duration.zero);
      b.add(const DashboardRefreshRequested());
    },
    skip: 2,
    expect: () => [
      const DashboardState(
        status: Status.success,
        summary: summary,
        mealTimes: [active],
        refreshing: true,
      ),
      const DashboardState(
        status: Status.success,
        summary: summary,
        mealTimes: [active],
        refreshError: 'offline',
      ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'refresh after a failed first load recovers',
    build: () {
      var calls = 0;
      when(() => getSummary(any())).thenAnswer((_) async {
        if (++calls == 1) throw const NetworkFailure('down');
        return summary;
      });
      return build();
    },
    act: (b) async {
      b.add(const DashboardStarted());
      await Future<void>.delayed(Duration.zero);
      b.add(const DashboardRefreshRequested());
    },
    skip: 2,
    expect: () => [
      isA<DashboardState>().having((s) => s.refreshing, 'refreshing', true),
      const DashboardState(
        status: Status.success,
        summary: summary,
        mealTimes: [active],
      ),
    ],
  );
}

import 'dart:io';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/error/failures.dart';
import 'package:ecuisine_mess/core/utils/status.dart';
import 'package:ecuisine_mess/features/reports/data/models/report_models.dart';
import 'package:ecuisine_mess/features/reports/domain/entities/report_entities.dart';
import 'package:ecuisine_mess/features/reports/domain/repositories/reports_repository.dart';
import 'package:ecuisine_mess/features/reports/domain/usecases/reports_usecases.dart';
import 'package:ecuisine_mess/features/reports/presentation/cubit/report_cubit.dart';
import 'package:ecuisine_mess/features/reports/presentation/pages/reports_page.dart';
import 'package:ecuisine_mess/shared/services/file_export_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ReportsRepository {}

class _FakeFiles implements FileExportService {
  String? name;
  List<int>? bytes;

  @override
  Future<String> save(String fileName, List<int> data) async {
    name = fileName;
    bytes = data;
    return r'C:\Downloads\' + fileName;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(const ReportQuery());
    registerFallbackValue(ReportKind.members);
  });

  group('ReportModels', () {
    test('attendance detail', () {
      final r = ReportModels.attendance({
        'view': 'attendance',
        'records': [
          {
            'member_id': 'M1',
            'name': 'Ali',
            'cuisine_name': 'Indian',
            'bill_date': '2026-10-06',
            'meal_type': 'LUNCH',
            'token_number': 'T-1',
            'bill_time': '12:30:00',
          },
        ],
      });
      expect(r.absenteesOnly, isFalse);
      expect(r.records.single.memberName, 'Ali');
      expect(r.count, 1);
    });

    test('attendance absentees', () {
      final r = ReportModels.attendance({
        'view': 'absentees',
        'records': [
          {'member_id': 'M2', 'member_name': 'Sara', 'phone': null},
        ],
      });
      expect(r.absenteesOnly, isTrue);
      expect(r.absentees.single.memberName, 'Sara');
      expect(r.absentees.single.phone, isNull);
      expect(r.records, isEmpty);
    });

    test('item movement parses decimal quantities', () {
      final rows = ReportModels.itemMovement([
        {
          'item_name': 'Rice',
          'unit': null,
          'cuisine_name': 'Indian',
          'category': 'Main',
          'total_quantity': 2.5,
          'served_count': 3,
        },
      ]);
      expect(rows.single.totalQuantity, 2.5);
      expect(rows.single.servedCount, 3);
      expect(rows.single.unit, isNull);
    });

    test('time distribution and members register', () {
      final t = ReportModels.timeDistribution({
        'interval_minutes': 30,
        'total_tokens': 5,
        'peak_slot': '12:00 - 12:30',
        'peak_count': 3,
        'slots': [
          {
            'slot': '12:00 - 12:30',
            'BREAKFAST': 0,
            'LUNCH': 3,
            'DINNER': 0,
            'total': 3,
          },
        ],
      });
      expect(t.peakCount, 3);
      expect(t.slots.single.lunch, 3);
      expect(t.firstTokenTime, isNull);

      final m = ReportModels.membersRegister({
        'total_members': 1,
        'summary': {
          'active': 1,
          'expired': 0,
          'suspended': 0,
          'by_cuisine': {'Indian': 1},
        },
        'members': [
          {
            'id': 'M1',
            'name': 'Ali',
            'rfid_tag': 'R1',
            'cuisine_name': 'Indian',
            'status': 'ACTIVE',
            'days_left': 12,
          },
        ],
      });
      expect(m.byCuisine, {'Indian': 1});
      expect(m.members.single.daysLeft, 12);
    });
  });

  group('ExportReportCsv', () {
    test('saves the server CSV under a stamped name', () async {
      final repo = _MockRepo();
      final files = _FakeFiles();
      when(
        () => repo.exportCsv(any(), any()),
      ).thenAnswer((_) async => Uint8List.fromList([1, 2, 3]));
      final export = ExportReportCsv(
        repo,
        files,
        clock: () => DateTime(2026, 10, 6, 9, 5, 7),
      );

      final path = await export(
        const ExportReportCsvParams(ReportKind.members, ReportQuery()),
      );

      expect(files.name, 'members_register_20261006_090507.csv');
      expect(files.bytes, [1, 2, 3]);
      expect(path, endsWith('members_register_20261006_090507.csv'));
    });
  });

  group('DownloadsFileExportService', () {
    test('never overwrites an existing file', () async {
      final dir = await Directory.systemTemp.createTemp('reports_test');
      addTearDown(() => dir.delete(recursive: true));
      final svc = DownloadsFileExportService(directory: dir);

      final a = await svc.save('x.csv', [1]);
      final b = await svc.save('x.csv', [2]);

      expect(a, isNot(b));
      expect(b, contains('x (1).csv'));
      expect(await File(a).readAsBytes(), [1]);
    });
  });

  group('ReportCubit', () {
    late _MockRepo repo;
    late _FakeFiles files;
    late GetItemMovementReport load;
    late ExportReportCsv export;
    const query = ReportQuery({'from_date': '2026-10-06'});

    setUp(() {
      repo = _MockRepo();
      files = _FakeFiles();
      load = GetItemMovementReport(repo);
      export = ExportReportCsv(repo, files);
    });

    ReportCubit<List<ItemMovementRow>> build() =>
        ReportCubit<List<ItemMovementRow>>(
          kind: ReportKind.itemMovement,
          load: load,
          export: export,
        );

    blocTest<ReportCubit<List<ItemMovementRow>>,
        ReportState<List<ItemMovementRow>>>(
      'generate loads data and remembers the query',
      build: () {
        when(() => repo.getItemMovement(any())).thenAnswer((_) async => []);
        return build();
      },
      act: (c) => c.generate(query),
      expect: () => [
        isA<ReportState<List<ItemMovementRow>>>().having(
          (s) => s.status,
          'status',
          Status.loading,
        ),
        isA<ReportState<List<ItemMovementRow>>>()
            .having((s) => s.status, 'status', Status.success)
            .having((s) => s.query, 'query', query),
      ],
    );

    blocTest<ReportCubit<List<ItemMovementRow>>,
        ReportState<List<ItemMovementRow>>>(
      'generate surfaces a failure message',
      build: () {
        when(
          () => repo.getItemMovement(any()),
        ).thenThrow(const ServerFailure('boom'));
        return build();
      },
      act: (c) => c.generate(query),
      verify: (c) {
        expect(c.state.status, Status.failure);
        expect(c.state.error, 'boom');
      },
    );

    test('export is a no-op before a report was generated', () async {
      final c = build();
      await c.exportCsv();
      verifyNever(() => repo.exportCsv(any(), any()));
      expect(files.name, isNull);
      await c.close();
    });

    test('export saves with the generated query and reports the path', () async {
      when(() => repo.getItemMovement(any())).thenAnswer((_) async => []);
      when(
        () => repo.exportCsv(any(), any()),
      ).thenAnswer((_) async => Uint8List.fromList([9]));
      final c = build();
      await c.generate(query);
      await c.exportCsv();

      verify(() => repo.exportCsv(ReportKind.itemMovement, query)).called(1);
      expect(c.state.notice, startsWith('Saved to'));
      expect(c.state.noticeIsError, isFalse);
      await c.close();
    });

    test('export failure becomes an error notice', () async {
      when(() => repo.getItemMovement(any())).thenAnswer((_) async => []);
      when(
        () => repo.exportCsv(any(), any()),
      ).thenThrow(const NetworkFailure());
      final c = build();
      await c.generate(query);
      await c.exportCsv();

      expect(c.state.noticeIsError, isTrue);
      expect(c.state.exporting, isFalse);
      await c.close();
    });
  });

  group('ReportsPage', () {
    late _MockRepo repo;

    setUp(() {
      repo = _MockRepo();
      when(() => repo.getAttendance(any())).thenAnswer(
        (_) async => const AttendanceReport(
          absenteesOnly: false,
          records: [
            AttendanceRecord(
              memberId: 'M1',
              memberName: 'Ali',
              cuisineName: 'Indian',
              billDate: '2026-10-06',
              mealType: 'LUNCH',
              tokenNumber: 'T-1',
              billTime: '12:30:00',
            ),
          ],
        ),
      );
      when(() => repo.getMembersRegister(any())).thenAnswer(
        (_) async => const MembersRegister(
          total: 0,
          active: 0,
          expired: 0,
          suspended: 0,
        ),
      );
      final files = _FakeFiles();
      for (final t in <Object>[
        GetAttendanceReport(repo),
        GetItemMovementReport(repo),
        GetTimeDistributionReport(repo),
        GetMembersRegister(repo),
        ExportReportCsv(repo, files),
      ]) {
        _register(t);
      }
    });

    tearDown(() async => sl.reset());

    Future<void> pump(WidgetTester t) async {
      await t.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
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
              child: ReportsView(
                loadCuisines: () async => {'c1': 'Indian'},
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    testWidgets('shows four tabs, generates attendance, export enables', (
      t,
    ) async {
      await pump(t);
      for (final label in [
        'Attendance',
        'Item Movement',
        'Time Distribution',
        'Members Register',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Choose filters and press Generate'), findsOneWidget);

      await t.tap(find.text('Generate'));
      await t.pumpAndSettle();

      expect(find.text('Ali'), findsOneWidget);
      verify(() => repo.getAttendance(any())).called(1);
      final export = t.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Export CSV'),
      );
      expect(export.onPressed, isNotNull);
    });

    testWidgets('empty members register shows the empty message', (t) async {
      await pump(t);
      await t.tap(find.text('Members Register'));
      await t.pumpAndSettle();
      await t.tap(find.text('Generate'));
      await t.pumpAndSettle();
      expect(find.text('No records for the selected filters'), findsOneWidget);
    });
  });
}

void _register(Object useCase) {
  switch (useCase) {
    case GetAttendanceReport u:
      sl.registerSingleton<GetAttendanceReport>(u);
    case GetItemMovementReport u:
      sl.registerSingleton<GetItemMovementReport>(u);
    case GetTimeDistributionReport u:
      sl.registerSingleton<GetTimeDistributionReport>(u);
    case GetMembersRegister u:
      sl.registerSingleton<GetMembersRegister>(u);
    case ExportReportCsv u:
      sl.registerSingleton<ExportReportCsv>(u);
  }
}

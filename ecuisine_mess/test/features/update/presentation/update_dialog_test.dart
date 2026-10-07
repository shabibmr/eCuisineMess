import 'package:ecuisine_mess/core/models/update_info.dart';
import 'package:ecuisine_mess/core/services/app_update_service.dart';
import 'package:ecuisine_mess/features/update/presentation/update_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppUpdateService extends Mock implements AppUpdateService {}

void main() {
  late MockAppUpdateService mockUpdateService;

  setUp(() {
    mockUpdateService = MockAppUpdateService();
  });

  Widget createWidget({
    required bool isMandatory,
    required UpdateInfo updateInfo,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: UpdateDialog(
          updateInfo: updateInfo,
          isMandatory: isMandatory,
          currentVersion: '1.0.0',
          updateService: mockUpdateService,
        ),
      ),
    );
  }

  testWidgets('UpdateDialog displays optional update details and action buttons',
      (tester) async {
    const updateInfo = UpdateInfo(
      version: '1.1.0',
      downloadUrl: 'https://vps.example.com/app.exe',
      releaseNotes: 'Fixed tap latency and improved performance',
    );

    await tester.pumpWidget(createWidget(
      isMandatory: false,
      updateInfo: updateInfo,
    ));

    expect(find.text('Update Available'), findsOneWidget);
    expect(find.text('v1.0.0 ➔ v1.1.0'), findsOneWidget);
    expect(find.text('Fixed tap latency and improved performance'), findsOneWidget);
    expect(find.text('Skip / Later'), findsOneWidget);
    expect(find.text('Update & Restart'), findsOneWidget);
  });

  testWidgets('UpdateDialog displays mandatory warning and hides Skip button',
      (tester) async {
    const updateInfo = UpdateInfo(
      version: '2.0.0',
      mandatory: true,
      downloadUrl: 'https://vps.example.com/app.exe',
      releaseNotes: 'Critical security update',
    );

    await tester.pumpWidget(createWidget(
      isMandatory: true,
      updateInfo: updateInfo,
    ));

    expect(find.text('Mandatory Update Required'), findsOneWidget);
    expect(find.text('This update is critical to counter operations and cannot be skipped.'),
        findsOneWidget);
    expect(find.text('Skip / Later'), findsNothing);
  });
}

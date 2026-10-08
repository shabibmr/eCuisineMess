import 'dart:io';
import 'package:ecuisine_mess/features/email/data/datasources/smtp_firestore_datasource.dart';
import 'package:ecuisine_mess/features/email/data/models/smtp_settings_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  HttpOverrides.global = _RealHttpOverrides();

  test('Live Firestore test: Read and Write SMTP configurations to ecuisine-mess',
      () async {
    final dataSource = SmtpFirestoreDataSourceImpl();

    // 1. Fetch current document from Cloud Firestore
    final settings =
        await dataSource.getSmtpSettings(projectId: 'ecuisine-mess');

    expect(settings.host, isNotEmpty);
    expect(settings.port, equals(587));
    expect(settings.fromEmail, equals('notifications@ecuisinemess.com'));
    expect(settings.username, equals('notifications@ecuisinemess.com'));
    expect(settings.useTls, isTrue);
    expect(settings.supervisorEmails, contains('supervisor1@ecuisinemess.com'));

    // 2. Update with modified timestamp / comment
    final updatedModel = const SmtpSettingsModel(
      host: 'smtp.gmail.com',
      port: 587,
      username: 'notifications@ecuisinemess.com',
      password: 'secure_app_password_123',
      fromEmail: 'notifications@ecuisinemess.com',
      fromName: 'eCuisine Mess System (Live Test Verified)',
      useTls: true,
      useSsl: false,
      supervisorEmails: [
        'supervisor1@ecuisinemess.com',
        'manager@ecuisinemess.com',
        'auditor@ecuisinemess.com',
      ],
      firebaseProjectId: 'ecuisine-mess',
    );

    await dataSource.saveSmtpSettings(updatedModel,
        projectId: 'ecuisine-mess');

    // 3. Read back and verify the update persisted in Firestore
    final readBack =
        await dataSource.getSmtpSettings(projectId: 'ecuisine-mess');

    expect(readBack.fromName, equals('eCuisine Mess System (Live Test Verified)'));
    expect(readBack.supervisorEmails, contains('auditor@ecuisinemess.com'));
  });
}

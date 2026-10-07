import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/features/email/data/datasources/smtp_firestore_datasource.dart';
import 'package:ecuisine_mess/features/email/data/models/smtp_settings_model.dart';
import 'package:ecuisine_mess/features/email/data/repositories/smtp_settings_repository_impl.dart';
import 'package:ecuisine_mess/features/email/domain/entities/smtp_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSmtpFirestoreDataSource extends Mock
    implements SmtpFirestoreDataSource {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const SmtpSettingsModel());
  });

  group('SmtpSettingsModel', () {
    test('parses from Firestore REST Document payload correctly', () {
      final doc = {
        'fields': {
          'host': {'stringValue': 'smtp.office365.com'},
          'port': {'integerValue': '587'},
          'username': {'stringValue': 'ops@ecuisine.ae'},
          'password': {'stringValue': 'secret123'},
          'fromEmail': {'stringValue': 'ops@ecuisine.ae'},
          'fromName': {'stringValue': 'eCuisine Counter'},
          'useTls': {'booleanValue': true},
          'useSsl': {'booleanValue': false},
          'supervisorEmails': {
            'arrayValue': {
              'values': [
                {'stringValue': 'sup1@ecuisine.ae'},
                {'stringValue': 'sup2@ecuisine.ae'},
              ]
            }
          }
        },
        'updateTime': '2026-10-07T10:00:00.000Z',
      };

      final model = SmtpSettingsModel.fromFirestore(doc, firebaseProjectId: 'ecuisine-mess');

      expect(model.host, 'smtp.office365.com');
      expect(model.port, 587);
      expect(model.username, 'ops@ecuisine.ae');
      expect(model.password, 'secret123');
      expect(model.fromEmail, 'ops@ecuisine.ae');
      expect(model.fromName, 'eCuisine Counter');
      expect(model.useTls, isTrue);
      expect(model.useSsl, isFalse);
      expect(model.supervisorEmails, ['sup1@ecuisine.ae', 'sup2@ecuisine.ae']);
      expect(model.firebaseProjectId, 'ecuisine-mess');
      expect(model.isConfigured, isTrue);
    });

    test('converts to Firestore REST fields map accurately', () {
      const model = SmtpSettingsModel(
        host: 'smtp.gmail.com',
        port: 465,
        username: 'user@gmail.com',
        password: 'pwd',
        fromEmail: 'user@gmail.com',
        fromName: 'Mess System',
        useTls: false,
        useSsl: true,
        supervisorEmails: ['admin@gmail.com'],
      );

      final fields = model.toFirestoreFields();

      expect(fields.containsKey('fields'), isTrue);
      final f = fields['fields'] as Map<String, dynamic>;
      expect(f['host']['stringValue'], 'smtp.gmail.com');
      expect(f['port']['integerValue'], '465');
      expect(f['useSsl']['booleanValue'], isTrue);
      expect(f['supervisorEmails']['arrayValue']['values'].first['stringValue'], 'admin@gmail.com');
    });
  });

  group('SmtpSettingsRepositoryImpl', () {
    late MockSmtpFirestoreDataSource mockDataSource;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      mockDataSource = MockSmtpFirestoreDataSource();
    });

    test('getSettings fetches from Firestore and caches in SharedPreferences', () async {
      const remoteModel = SmtpSettingsModel(
        host: 'smtp.gmail.com',
        port: 587,
        fromEmail: 'remote@gmail.com',
        supervisorEmails: ['sup@gmail.com'],
      );

      when(() => mockDataSource.getSmtpSettings(projectId: any(named: 'projectId')))
          .thenAnswer((_) async => remoteModel);

      final repo = SmtpSettingsRepositoryImpl(
        firestoreDataSource: mockDataSource,
        prefs: prefs,
      );

      final result = await repo.getSettings();

      expect(result.host, 'smtp.gmail.com');
      expect(result.fromEmail, 'remote@gmail.com');
      expect(prefs.containsKey(AppConstants.smtpSettingsCachePrefsKey), isTrue);
    });

    test('getSettings falls back to cached settings when Firestore fails', () async {
      await prefs.setString(
        AppConstants.smtpSettingsCachePrefsKey,
        '{"host":"cached.smtp.com","port":587,"fromEmail":"cached@domain.com"}',
      );

      when(() => mockDataSource.getSmtpSettings(projectId: any(named: 'projectId')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: '')));

      final repo = SmtpSettingsRepositoryImpl(
        firestoreDataSource: mockDataSource,
        prefs: prefs,
      );

      final result = await repo.getSettings();

      expect(result.host, 'cached.smtp.com');
      expect(result.fromEmail, 'cached@domain.com');
    });

    test('saveSettings writes to Firestore and updates cache', () async {
      const newSettings = SmtpSettings(
        host: 'smtp.sendgrid.net',
        port: 587,
        fromEmail: 'alerts@domain.com',
      );

      when(() => mockDataSource.saveSmtpSettings(any(), projectId: any(named: 'projectId')))
          .thenAnswer((_) async {});

      final repo = SmtpSettingsRepositoryImpl(
        firestoreDataSource: mockDataSource,
        prefs: prefs,
      );

      await repo.saveSettings(newSettings);

      expect(repo.currentSettings.host, 'smtp.sendgrid.net');
      expect(prefs.containsKey(AppConstants.smtpSettingsCachePrefsKey), isTrue);
      verify(() => mockDataSource.saveSmtpSettings(any(), projectId: any(named: 'projectId'))).called(1);
    });
  });
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/services/app_update_service.dart';
import 'package:ecuisine_mess/shared/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirestoreService extends Mock implements FirestoreService {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirestoreService mockFirestoreService;
  late MockDocumentSnapshot mockSnapshot;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    mockSnapshot = MockDocumentSnapshot();
  });

  group('AppUpdateService.checkForUpdate', () {
    test('returns noUpdate when document does not exist', () async {
      when(() => mockFirestoreService.getDoc('app_updates', any()))
          .thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockSnapshot.data()).thenReturn(null);

      final service = AppUpdateService(firestoreService: mockFirestoreService);
      final result = await service.checkForUpdate(
        overrideCurrentVersion: '1.0.0',
        overrideCurrentBuildNumber: 1,
      );

      expect(result.hasUpdate, isFalse);
      expect(result.isMandatory, isFalse);
      expect(result.currentVersion, '1.0.0');
    });

    test('returns available update when remote version is higher', () async {
      when(() => mockFirestoreService.getDoc('app_updates', any()))
          .thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'version': '1.1.0',
        'build_number': 5,
        'mandatory': false,
        'download_url': 'https://vps.example.com/app.exe',
        'release_notes': 'Bug fixes',
      });

      final service = AppUpdateService(firestoreService: mockFirestoreService);
      final result = await service.checkForUpdate(
        overrideCurrentVersion: '1.0.0',
        overrideCurrentBuildNumber: 1,
      );

      expect(result.hasUpdate, isTrue);
      expect(result.isMandatory, isFalse);
      expect(result.updateInfo?.version, '1.1.0');
      expect(result.updateInfo?.releaseNotes, 'Bug fixes');
    });

    test('flags isMandatory when mandatory is true in Firestore', () async {
      when(() => mockFirestoreService.getDoc('app_updates', any()))
          .thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'version': '1.2.0',
        'mandatory': true,
        'download_url': 'https://vps.example.com/app.exe',
      });

      final service = AppUpdateService(firestoreService: mockFirestoreService);
      final result = await service.checkForUpdate(
        overrideCurrentVersion: '1.0.0',
      );

      expect(result.hasUpdate, isTrue);
      expect(result.isMandatory, isTrue);
    });

    test('returns error result gracefully on Firestore failure', () async {
      when(() => mockFirestoreService.getDoc('app_updates', any()))
          .thenThrow(Exception('Firestore connection failure'));

      final service = AppUpdateService(firestoreService: mockFirestoreService);
      final result = await service.checkForUpdate(
        overrideCurrentVersion: '1.0.0',
      );

      expect(result.hasUpdate, isFalse);
      expect(result.errorMessage, contains('Firestore connection failure'));
    });
  });

  group('AppUpdateService.verifyChecksum', () {
    test('correctly verifies SHA-256 match and mismatch', () async {
      final tempDir = await Directory.systemTemp.createTemp('update_test_');
      final tempFile = File('${tempDir.path}/test.bin');
      await tempFile.writeAsString('hello world');

      final digest = sha256.convert('hello world'.codeUnits).toString();
      final service = AppUpdateService(firestoreService: mockFirestoreService);

      expect(await service.verifyChecksum(tempFile, digest), isTrue);
      expect(await service.verifyChecksum(tempFile, '000000000000'), isFalse);

      await tempDir.delete(recursive: true);
    });
  });

  group('AppUpdateService DI registration', () {
    test('configureDependencies registers AppUpdateService with DI', () async {
      SharedPreferences.setMockInitialValues({});
      await sl.reset();
      await configureDependencies(firestore: MockFirebaseFirestore());

      expect(sl.isRegistered<AppUpdateService>(), isTrue);
      await sl.reset();
    });
  });
}

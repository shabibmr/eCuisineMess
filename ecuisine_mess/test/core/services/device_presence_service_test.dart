import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecuisine_mess/core/services/device_presence_service.dart';
import 'package:ecuisine_mess/shared/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirestoreService extends Mock implements FirestoreService {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirestoreService firestore;
  late MockDocumentSnapshot snapshot;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    firestore = MockFirestoreService();
    snapshot = MockDocumentSnapshot();
    when(() => firestore.isAvailable).thenReturn(true);
    when(() => firestore.getDoc(any(), any())).thenAnswer((_) async => snapshot);
    when(() => firestore.setDoc(any(), any(), any())).thenAnswer((_) async {});
    when(() => firestore.updateDoc(any(), any(), any())).thenAnswer((_) async {});
  });

  Future<DevicePresenceService> build({
    Map<String, Object> prefs = const {},
    String? machineGuid = 'machine-1',
    DateTime? now,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    return DevicePresenceService(
      firestoreService: firestore,
      prefs: await SharedPreferences.getInstance(),
      readMachineGuid: () async => machineGuid,
      createInstallId: () => 'install-generated',
      now: () => now ?? DateTime.utc(2026, 10, 16, 8, 30),
    );
  }

  Map<String, dynamic> capturedSet() {
    return verify(() => firestore.setDoc('devices', any(), captureAny()))
        .captured
        .single as Map<String, dynamic>;
  }

  test('creates the device with first switch-on and last login', () async {
    when(() => snapshot.exists).thenReturn(false);
    final service = await build();

    await service.record();

    final data = capturedSet();
    expect(data[DevicePresenceService.deviceIdField], 'machine-1');
    expect(data[DevicePresenceService.firstSwitchOnField], isA<Timestamp>());
    expect(
      data[DevicePresenceService.lastLoginField],
      data[DevicePresenceService.firstSwitchOnField],
    );
    verifyNever(() => firestore.updateDoc(any(), any(), any()));
  });

  test('updates last login and leaves the original switch-on alone', () async {
    when(() => snapshot.exists).thenReturn(true);
    final service = await build(
      prefs: {
        DevicePresenceService.firstSwitchOnPrefsKey: '2026-01-02T03:04:05.000Z',
      },
      now: DateTime.utc(2026, 10, 16, 9),
    );

    await service.record();

    final data = verify(
      () => firestore.updateDoc('devices', 'machine-1', captureAny()),
    ).captured.single as Map<String, dynamic>;
    expect(data.keys, [DevicePresenceService.lastLoginField]);
    expect(
      (data[DevicePresenceService.lastLoginField] as Timestamp).toDate().toUtc(),
      DateTime.utc(2026, 10, 16, 9),
    );
    verifyNever(() => firestore.setDoc(any(), any(), any()));
  });

  test('uses the saved first switch-on when the document is created later', () async {
    when(() => snapshot.exists).thenReturn(false);
    final service = await build(
      prefs: {
        DevicePresenceService.firstSwitchOnPrefsKey: '2026-01-02T03:04:05.000Z',
      },
      now: DateTime.utc(2026, 10, 16, 9),
    );

    await service.record();

    final data = capturedSet();
    expect(
      (data[DevicePresenceService.firstSwitchOnField] as Timestamp).toDate().toUtc(),
      DateTime.utc(2026, 1, 2, 3, 4, 5),
    );
    expect(
      (data[DevicePresenceService.lastLoginField] as Timestamp).toDate().toUtc(),
      DateTime.utc(2026, 10, 16, 9),
    );
  });

  test('keeps a stored install id when the machine id is missing', () async {
    when(() => snapshot.exists).thenReturn(true);
    final service = await build(
      machineGuid: null,
      prefs: {DevicePresenceService.deviceIdPrefsKey: 'install-kept'},
    );

    await service.record();

    verify(() => firestore.updateDoc('devices', 'install-kept', any())).called(1);
  });

  test('does not call Firestore when Firebase is unavailable', () async {
    when(() => firestore.isAvailable).thenReturn(false);
    final service = await build();

    await service.record();

    verifyNever(() => firestore.getDoc(any(), any()));
  });
}

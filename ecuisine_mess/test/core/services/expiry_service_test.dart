import 'package:ecuisine_mess/core/services/expiry_service.dart';
import 'package:ecuisine_mess/shared/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ExpiryService> build(Map<String, Object> prefs, DateTime now) async {
    SharedPreferences.setMockInitialValues(prefs);
    return ExpiryService(
      prefs: await SharedPreferences.getInstance(),
      firestoreService: FirestoreService(),
      now: () => now,
    );
  }

  test('parses dd-MM-yyyy, dd-MMM-yyyy, and ISO strings', () {
    expect(ExpiryService.parseExpiry('30-oct-2026'), DateTime(2026, 10, 30));
    expect(ExpiryService.parseExpiry('30-Oct-2026'), DateTime(2026, 10, 30));
    expect(ExpiryService.parseExpiry('30-10-2026'), DateTime(2026, 10, 30));
    expect(ExpiryService.parseExpiry('2026-10-30'), DateTime(2026, 10, 30));
    expect(ExpiryService.parseExpiry({'stringValue': '30-oct-2026'}), DateTime(2026, 10, 30));
    expect(ExpiryService.parseExpiry('garbage'), isNull);
    expect(ExpiryService.parseExpiry(null), isNull);
  });

  test('not expired on or before the expiry day', () async {
    final s = await build(
      {ExpiryService.prefsKey: '2026-10-30'},
      DateTime(2026, 10, 30, 23, 59),
    );
    expect(s.expired.value, isFalse);
  });

  test('expired the day after the expiry date', () async {
    final s = await build(
      {ExpiryService.prefsKey: '2026-10-30'},
      DateTime(2026, 10, 31),
    );
    expect(s.expired.value, isTrue);
  });

  test('no cached date means not expired', () async {
    final s = await build({}, DateTime(2030));
    expect(s.expired.value, isFalse);
  });

  test('refresh without Firebase is silent and keeps the cache', () async {
    final s = await build(
      {ExpiryService.prefsKey: '2026-10-30'},
      DateTime(2026, 11, 5),
    );
    await s.refresh();
    expect(s.expired.value, isTrue);
  });

  test('refresh fetches live expiry_date from Firestore app_config/license', () async {
    final s = await build({}, DateTime(2026, 10, 12));
    expect(s.expired.value, isFalse);
    await s.refresh();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ExpiryService.prefsKey), equals('2026-10-30'));
    expect(s.expired.value, isFalse);
  });
}

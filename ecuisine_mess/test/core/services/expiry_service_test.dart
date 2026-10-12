import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/services/expiry_service.dart';
import 'package:ecuisine_mess/shared/services/firestore_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Answers every request with [body], or fails when [body] is null.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);
  final Map<String, dynamic>? body;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (body == null) {
      throw DioException(requestOptions: options, message: 'offline');
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _doc(Map<String, dynamic> field) => {
      'fields': {'expiry_date': field},
    };

void main() {
  Future<ExpiryService> build(
    Map<String, Object> prefs,
    DateTime now, {
    Map<String, dynamic>? remote,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    return ExpiryService(
      prefs: await SharedPreferences.getInstance(),
      firestoreService: FirestoreService(),
      dioClient: Dio()..httpClientAdapter = _FakeAdapter(remote),
      now: () => now,
    );
  }

  group('parseExpiry', () {
    test('accepts the supported formats', () {
      final oct30 = DateTime(2026, 10, 30);
      expect(ExpiryService.parseExpiry('30-10-2026'), oct30);
      expect(ExpiryService.parseExpiry('30/10/2026'), oct30);
      expect(ExpiryService.parseExpiry('30-oct-2026'), oct30);
      expect(ExpiryService.parseExpiry('30 October 2026'), oct30);
      expect(ExpiryService.parseExpiry('Oct 30, 2026'), oct30);
      expect(ExpiryService.parseExpiry('2026-10-30'), oct30);
      expect(ExpiryService.parseExpiry({'stringValue': '30-10-2026'}), oct30);
    });

    test('rejects invalid dates instead of rolling over', () {
      expect(ExpiryService.parseExpiry('31-02-2026'), isNull);
      expect(ExpiryService.parseExpiry('31-04-2026'), isNull);
      expect(ExpiryService.parseExpiry('30-13-2026'), isNull);
      expect(ExpiryService.parseExpiry('30-octopus-2026'), isNull);
      expect(ExpiryService.parseExpiry('garbage'), isNull);
      expect(ExpiryService.parseExpiry(''), isNull);
      expect(ExpiryService.parseExpiry(null), isNull);
    });

    test('converts zoned instants to the local date', () {
      const iso = '2026-10-29T18:30:00Z';
      final local = DateTime.parse(iso).toLocal();
      final expected = DateTime(local.year, local.month, local.day);
      expect(ExpiryService.parseExpiry(iso), expected);
      expect(ExpiryService.parseExpiry({'timestampValue': iso}), expected);
    });
  });

  group('expiry evaluation', () {
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

    test('a corrupt cached date means not expired', () async {
      final s = await build({ExpiryService.prefsKey: 'junk'}, DateTime(2030));
      expect(s.expired.value, isFalse);
    });
  });

  group('refresh', () {
    test('offline keeps the cached date and never throws', () async {
      final s = await build(
        {ExpiryService.prefsKey: '2026-10-30'},
        DateTime(2026, 11, 5),
      );
      await s.refresh();
      expect(s.expired.value, isTrue);
    });

    test('stores the fetched date locally', () async {
      final s = await build(
        {},
        DateTime(2026, 10, 12),
        remote: _doc({'stringValue': '30-10-2026'}),
      );
      await s.refresh();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ExpiryService.prefsKey), '2026-10-30');
      expect(s.expired.value, isFalse);
    });

    test('a fetched past date locks the app', () async {
      final s = await build(
        {},
        DateTime(2026, 10, 12),
        remote: _doc({'stringValue': '01-01-2026'}),
      );
      await s.refresh();
      expect(s.expired.value, isTrue);
    });

    test('a missing field leaves the cache untouched', () async {
      final s = await build(
        {ExpiryService.prefsKey: '2026-10-30'},
        DateTime(2026, 10, 12),
        remote: {'fields': <String, dynamic>{}},
      );
      await s.refresh();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ExpiryService.prefsKey), '2026-10-30');
    });
  });

  testWidgets('re-checks the local date every minute without a refresh',
      (tester) async {
    var now = DateTime(2026, 10, 30, 23, 59, 30);
    SharedPreferences.setMockInitialValues(
      {ExpiryService.prefsKey: '2026-10-30'},
    );
    final clocked = ExpiryService(
      prefs: await SharedPreferences.getInstance(),
      firestoreService: FirestoreService(),
      dioClient: Dio()..httpClientAdapter = _FakeAdapter(null),
      now: () => now,
    );
    unawaited(clocked.start());
    await tester.pump();
    expect(clocked.expired.value, isFalse);

    now = DateTime(2026, 10, 31, 0, 0, 30);
    await tester.pump(const Duration(minutes: 1));
    expect(clocked.expired.value, isTrue);
    clocked.dispose();
  });
}

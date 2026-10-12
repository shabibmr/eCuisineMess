import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/shared/services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Silent expiry gate.
///
/// Reads `app_config/license.expiry_date` from Firestore on start, caches it in
/// [SharedPreferences], and exposes [expired]. The app shows a blank blue
/// screen once the current date is past the expiry date. Failures never
/// surface: with no network the cached date is used, with no cache the app runs.
class ExpiryService {
  ExpiryService({
    required SharedPreferences prefs,
    required FirestoreService firestoreService,
    Dio? dioClient,
    DateTime Function()? now,
    this.collectionPath = 'app_config',
    this.docId = 'license',
    this.field = 'expiry_date',
    this.projectId = AppConstants.defaultFirebaseProjectId,
  })  : _prefs = prefs,
        _firestore = firestoreService,
        _dio = dioClient,
        _now = now ?? DateTime.now {
    _evaluate();
  }

  static const prefsKey = 'license_expiry_date';

  final SharedPreferences _prefs;
  final FirestoreService _firestore;
  final Dio? _dio;
  final DateTime Function() _now;
  final String collectionPath;
  final String docId;
  final String field;
  final String projectId;

  Timer? _timer;
  Dio? _ownedDio;
  int _ticks = 0;

  /// True once the current date is past the stored expiry date.
  final ValueNotifier<bool> expired = ValueNotifier<bool>(false);

  /// Refreshes from Firestore now, re-checks the cached date every minute (so
  /// midnight is noticed promptly) and re-fetches hourly.
  Future<void> start() async {
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      _ticks++;
      if (_ticks % 60 == 0) {
        unawaited(refresh());
      } else {
        _evaluate();
      }
    });
    await refresh();
  }

  void dispose() {
    _timer?.cancel();
    _ownedDio?.close();
    expired.dispose();
  }

  /// Fetches the expiry date, stores it locally and re-evaluates. Never throws.
  Future<void> refresh() async {
    try {
      DateTime? date;

      // 1. Cloud Firestore SDK, when available.
      try {
        if (_firestore.isAvailable) {
          final snap = await _firestore
              .getDoc(collectionPath, docId)
              .timeout(const Duration(seconds: 10));
          date = parseExpiry(snap.data()?[field]);
        }
      } catch (_) {
        // Fall through to the REST fallback.
      }

      // 2. Firestore REST fallback if the SDK was unavailable or failed.
      if (date == null) {
        try {
          date = await _fetchFromRest();
        } catch (_) {
          // Silent by design; the cached value stays in effect.
        }
      }

      if (date != null) {
        await _prefs.setString(prefsKey, _format(date));
      }
    } catch (_) {
      // Silent by design.
    }
    _evaluate();
  }

  Future<DateTime?> _fetchFromRest() async {
    final dio = _dio ??
        (_ownedDio ??= Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        )));
    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionPath/$docId';
    final response = await dio.get<Map<String, dynamic>>(url);
    final fields = response.data?['fields'];
    return fields is Map ? parseExpiry(fields[field]) : null;
  }

  void _evaluate() {
    final stored = _prefs.getString(prefsKey);
    final date = stored == null ? null : parseExpiry(stored);
    if (date == null) return;
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    // The expiry day itself is still valid.
    expired.value = today.isAfter(date);
  }

  static String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static const _months = <String>[
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];

  static final _dmyRe = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$');
  static final _dMonYRe =
      RegExp(r'^(\d{1,2})[-/.\s]+([a-zA-Z]+)[-/.\s]+(\d{4})$');
  static final _monDYRe =
      RegExp(r'^([a-zA-Z]+)[-/.\s]+(\d{1,2})[-/.\s,]+(\d{4})$');

  /// Builds a date-only value, or null if the day does not exist in that
  /// month (so `31-02-2026` is rejected instead of rolling over to March).
  static DateTime? _ymd(int y, int m, int d) {
    final date = DateTime(y, m, d);
    return date.year == y && date.month == m && date.day == d ? date : null;
  }

  /// Month number for a full or three-letter English month name.
  static int? _month(String name) {
    final n = name.toLowerCase();
    final i = _months.indexWhere((m) => m == n || m.substring(0, 3) == n);
    return i < 0 ? null : i + 1;
  }

  /// Accepts a Firestore [Timestamp], a Firestore REST field map, `yyyy-MM-dd`
  /// (optionally with a time/zone), `dd-MM-yyyy`, `dd-MMM-yyyy` or
  /// `MMM-dd-yyyy`. Instants with a zone are converted to local time.
  /// Returns a date-only local [DateTime], or null if unparseable.
  @visibleForTesting
  static DateTime? parseExpiry(Object? raw) {
    if (raw is Timestamp) {
      final d = raw.toDate().toLocal();
      return DateTime(d.year, d.month, d.day);
    }
    if (raw is Map) {
      return parseExpiry(raw['stringValue'] ?? raw['timestampValue']);
    }
    if (raw is! String) return null;
    final s = raw.trim();

    final dmy = _dmyRe.firstMatch(s);
    if (dmy != null) {
      return _ymd(int.parse(dmy[3]!), int.parse(dmy[2]!), int.parse(dmy[1]!));
    }

    final dMonY = _dMonYRe.firstMatch(s);
    if (dMonY != null) {
      final m = _month(dMonY[2]!);
      return m == null ? null : _ymd(int.parse(dMonY[3]!), m, int.parse(dMonY[1]!));
    }

    final monDY = _monDYRe.firstMatch(s);
    if (monDY != null) {
      final m = _month(monDY[1]!);
      return m == null ? null : _ymd(int.parse(monDY[3]!), m, int.parse(monDY[2]!));
    }

    final d = DateTime.tryParse(s)?.toLocal();
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }
}

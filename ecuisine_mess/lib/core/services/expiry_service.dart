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

  /// True once the current date is past the stored expiry date.
  final ValueNotifier<bool> expired = ValueNotifier<bool>(false);

  /// Refreshes from Firestore now and then hourly.
  Future<void> start() async {
    _timer ??= Timer.periodic(const Duration(hours: 1), (_) => refresh());
    await refresh();
  }

  void dispose() {
    _timer?.cancel();
    expired.dispose();
  }

  /// Fetches the expiry date, stores it locally and re-evaluates. Silent.
  Future<void> refresh() async {
    DateTime? date;

    // 1. Try Cloud Firestore SDK if available.
    try {
      if (_firestore.isAvailable) {
        final snap = await _firestore
            .getDoc(collectionPath, docId)
            .timeout(const Duration(seconds: 10));
        date = parseExpiry(snap.data()?[field]);
      }
    } catch (_) {
      // Fall through to REST API fallback.
    }

    // 2. Direct Firestore REST API fallback if SDK was unavailable or failed.
    if (date == null) {
      try {
        date = await _fetchFromRest();
      } catch (_) {
        // Silent by design; fall back to the cached value.
      }
    }

    if (date != null) {
      await _prefs.setString(prefsKey, _format(date));
    }

    _evaluate();
  }

  Future<DateTime?> _fetchFromRest() async {
    final dio = _dio ?? Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    final url =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collectionPath/$docId';
    final response = await dio.get<Map<String, dynamic>>(url);
    if (response.data != null) {
      final fields = response.data!['fields'];
      if (fields is Map<String, dynamic>) {
        final fieldVal = fields[field];
        return parseExpiry(fieldVal);
      }
    }
    return null;
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

  static const _monthMap = <String, int>{
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  /// Accepts a Firestore [Timestamp], Firestore REST field map, `yyyy-MM-dd`,
  /// `dd-MM-yyyy`, or `dd-MMM-yyyy` (e.g. `30-oct-2026`).
  /// Returns a date-only local [DateTime], or null if unparseable.
  @visibleForTesting
  static DateTime? parseExpiry(Object? raw) {
    if (raw == null) return null;
    if (raw is Timestamp) {
      final d = raw.toDate().toLocal();
      return DateTime(d.year, d.month, d.day);
    }
    if (raw is Map) {
      if (raw['stringValue'] != null) {
        return parseExpiry(raw['stringValue']);
      }
      if (raw['timestampValue'] != null) {
        return parseExpiry(raw['timestampValue']);
      }
    }
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return null;

      // 1. dd-MM-yyyy or dd/MM/yyyy
      final dmy = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$').firstMatch(s);
      if (dmy != null) {
        final day = int.parse(dmy.group(1)!);
        final month = int.parse(dmy.group(2)!);
        final year = int.parse(dmy.group(3)!);
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }

      // 2. dd-MMM-yyyy (e.g. 30-oct-2026, 30-Oct-2026, 30 October 2026)
      final dMmmY = RegExp(r'^(\d{1,2})[-/.\s]+([a-zA-Z]+)[-/.\s]+(\d{4})$').firstMatch(s);
      if (dMmmY != null) {
        final day = int.parse(dMmmY.group(1)!);
        final monthStr = dMmmY.group(2)!.toLowerCase();
        final year = int.parse(dMmmY.group(3)!);
        final month = _monthMap[monthStr];
        if (month != null && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }

      // 3. MMM-dd-yyyy (e.g. oct-30-2026, October 30 2026)
      final mmmDY = RegExp(r'^([a-zA-Z]+)[-/.\s]+(\d{1,2})[-/.\s,]+(\d{4})$').firstMatch(s);
      if (mmmDY != null) {
        final monthStr = mmmDY.group(1)!.toLowerCase();
        final day = int.parse(mmmDY.group(2)!);
        final year = int.parse(mmmDY.group(3)!);
        final month = _monthMap[monthStr];
        if (month != null && day >= 1 && day <= 31) {
          return DateTime(year, month, day);
        }
      }

      // 4. ISO-8601 strings (e.g. 2026-10-30)
      final d = DateTime.tryParse(s);
      if (d != null) return DateTime(d.year, d.month, d.day);
    }
    return null;
  }
}

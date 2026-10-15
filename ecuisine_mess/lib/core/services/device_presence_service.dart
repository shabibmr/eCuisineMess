import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecuisine_mess/shared/services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records this Windows PC in Firestore.
///
/// The document id is the machine id. `first_switch_on` is written only when
/// the document is created. `last_login` is updated on every app start.
/// The first local launch time is kept even if that launch had no network.
class DevicePresenceService {
  DevicePresenceService({
    required FirestoreService firestoreService,
    required SharedPreferences prefs,
    Future<String?> Function()? readMachineGuid,
    String Function()? createInstallId,
    DateTime Function()? now,
    this.collectionPath = 'devices',
  })  : _firestore = firestoreService,
        _prefs = prefs,
        _readMachineGuid = readMachineGuid ?? readWindowsMachineGuid,
        _createInstallId = createInstallId ?? _newInstallId,
        _now = now ?? DateTime.now;

  static const deviceIdPrefsKey = 'mess_device_id';
  static const firstSwitchOnPrefsKey = 'mess_first_switch_on';

  static const deviceIdField = 'device_id';
  static const firstSwitchOnField = 'first_switch_on';
  static const lastLoginField = 'last_login';

  final FirestoreService _firestore;
  final SharedPreferences _prefs;
  final Future<String?> Function() _readMachineGuid;
  final String Function() _createInstallId;
  final DateTime Function() _now;
  final String collectionPath;

  /// Writes the device document. Never throws.
  Future<void> record() async {
    try {
      final deviceId = await resolveDeviceId(
        readMachineGuid: _readMachineGuid,
        prefs: _prefs,
        createInstallId: _createInstallId,
      );
      final now = _now();
      final startedAt = await rememberFirstSwitchOn(_prefs, now);
      if (!_firestore.isAvailable) return;

      final snap = await _firestore.getDoc(collectionPath, deviceId);
      final lastLogin = Timestamp.fromDate(now);
      if (!snap.exists) {
        await _firestore.setDoc(collectionPath, deviceId, {
          deviceIdField: deviceId,
          firstSwitchOnField: Timestamp.fromDate(startedAt),
          lastLoginField: lastLogin,
        });
        return;
      }
      await _firestore.updateDoc(collectionPath, deviceId, {
        lastLoginField: lastLogin,
      });
    } catch (_) {
      // Offline or a rules failure must not block startup.
    }
  }

  /// Machine id when Windows can provide one, otherwise a stored install id.
  static Future<String> resolveDeviceId({
    required Future<String?> Function() readMachineGuid,
    required SharedPreferences prefs,
    required String Function() createInstallId,
  }) async {
    final machine = _clean(await readMachineGuid());
    if (machine != null) {
      await prefs.setString(deviceIdPrefsKey, machine);
      return machine;
    }
    final cached = _clean(prefs.getString(deviceIdPrefsKey));
    if (cached != null) return cached;
    final created = _clean(createInstallId()) ?? _newInstallId();
    await prefs.setString(deviceIdPrefsKey, created);
    return created;
  }

  /// Returns the first local switch-on time, storing [now] when none exists.
  static Future<DateTime> rememberFirstSwitchOn(
    SharedPreferences prefs,
    DateTime now,
  ) async {
    final stored = prefs.getString(firstSwitchOnPrefsKey);
    final parsed = stored == null ? null : DateTime.tryParse(stored);
    if (parsed != null) return parsed;
    await prefs.setString(firstSwitchOnPrefsKey, now.toIso8601String());
    return now;
  }

  static String? _clean(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value == '.' || value == '..') return null;
    final safe = value.replaceAll('/', '_');
    return safe.length > 1500 ? safe.substring(0, 1500) : safe;
  }

  static String _newInstallId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}

/// Reads `HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid`.
Future<String?> readWindowsMachineGuid() async {
  if (!Platform.isWindows) return null;
  try {
    final result = await Process.run(
      'reg',
      [
        'query',
        r'HKLM\SOFTWARE\Microsoft\Cryptography',
        '/v',
        'MachineGuid',
      ],
    );
    if (result.exitCode != 0) return null;
    final match = RegExp(
      r'MachineGuid\s+REG_SZ\s+(\S+)',
    ).firstMatch('${result.stdout}');
    return match?.group(1);
  } catch (_) {
    return null;
  }
}

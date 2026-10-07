import 'package:ecuisine_mess/features/email/domain/entities/smtp_settings.dart';

/// Serialization model for SmtpSettings.
/// Handles both standard JSON (for SharedPreferences caching)
/// and Firestore REST API document formats (`fields` mapping).
class SmtpSettingsModel extends SmtpSettings {
  const SmtpSettingsModel({
    super.host,
    super.port,
    super.username,
    super.password,
    super.fromEmail,
    super.fromName,
    super.useTls,
    super.useSsl,
    super.supervisorEmails,
    super.firebaseProjectId,
    super.updatedAt,
  });

  factory SmtpSettingsModel.fromEntity(SmtpSettings entity) {
    return SmtpSettingsModel(
      host: entity.host,
      port: entity.port,
      username: entity.username,
      password: entity.password,
      fromEmail: entity.fromEmail,
      fromName: entity.fromName,
      useTls: entity.useTls,
      useSsl: entity.useSsl,
      supervisorEmails: entity.supervisorEmails,
      firebaseProjectId: entity.firebaseProjectId,
      updatedAt: entity.updatedAt,
    );
  }

  /// Parses from standard JSON map (used by SharedPreferences cache)
  factory SmtpSettingsModel.fromJson(Map<String, dynamic> json) {
    List<String> supervisors = [];
    final rawSupervisors = json['supervisorEmails'];
    if (rawSupervisors is List) {
      supervisors = rawSupervisors.map((e) => e.toString().trim()).toList();
    } else if (rawSupervisors is String && rawSupervisors.isNotEmpty) {
      supervisors = rawSupervisors
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return SmtpSettingsModel(
      host: json['host']?.toString() ?? '',
      port: int.tryParse(json['port']?.toString() ?? '') ?? 587,
      username: json['username']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      fromEmail: json['fromEmail']?.toString() ?? '',
      fromName: json['fromName']?.toString() ?? 'eCuisine Mess System',
      useTls: json['useTls'] == true || json['useTls']?.toString() == 'true',
      useSsl: json['useSsl'] == true || json['useSsl']?.toString() == 'true',
      supervisorEmails: supervisors,
      firebaseProjectId: json['firebaseProjectId']?.toString() ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// Parses from a Cloud Firestore Document response (either REST API with `fields`
  /// or directly decoded document map).
  factory SmtpSettingsModel.fromFirestore(
    Map<String, dynamic> doc, {
    String firebaseProjectId = '',
  }) {
    // If wrapped in Firestore REST "fields" object
    if (doc.containsKey('fields') && doc['fields'] is Map) {
      final fields = doc['fields'] as Map<String, dynamic>;
      final updateTime = doc['updateTime']?.toString();

      List<String> supervisors = [];
      final supField = fields['supervisorEmails'];
      if (supField is Map && supField.containsKey('arrayValue')) {
        final values = supField['arrayValue']?['values'];
        if (values is List) {
          supervisors = values
              .map((v) => v is Map ? v['stringValue']?.toString() ?? '' : '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } else if (supField is Map && supField.containsKey('stringValue')) {
        supervisors = (supField['stringValue']?.toString() ?? '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      String extractString(String key, [String fallback = '']) {
        final val = fields[key];
        if (val is Map && val.containsKey('stringValue')) {
          return val['stringValue']?.toString() ?? fallback;
        }
        return fallback;
      }

      int extractInt(String key, [int fallback = 587]) {
        final val = fields[key];
        if (val is Map) {
          if (val.containsKey('integerValue')) {
            return int.tryParse(val['integerValue'].toString()) ?? fallback;
          }
          if (val.containsKey('stringValue')) {
            return int.tryParse(val['stringValue'].toString()) ?? fallback;
          }
        }
        return fallback;
      }

      bool extractBool(String key, [bool fallback = false]) {
        final val = fields[key];
        if (val is Map && val.containsKey('booleanValue')) {
          return val['booleanValue'] == true;
        }
        return fallback;
      }

      return SmtpSettingsModel(
        host: extractString('host'),
        port: extractInt('port', 587),
        username: extractString('username'),
        password: extractString('password'),
        fromEmail: extractString('fromEmail'),
        fromName: extractString('fromName', 'eCuisine Mess System'),
        useTls: extractBool('useTls', true),
        useSsl: extractBool('useSsl', false),
        supervisorEmails: supervisors,
        firebaseProjectId: firebaseProjectId,
        updatedAt: updateTime != null ? DateTime.tryParse(updateTime) : null,
      );
    }

    // Direct plain map fallback
    return SmtpSettingsModel.fromJson(doc);
  }

  /// Converts to standard JSON map for SharedPreferences storage.
  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'fromEmail': fromEmail,
      'fromName': fromName,
      'useTls': useTls,
      'useSsl': useSsl,
      'supervisorEmails': supervisorEmails,
      'firebaseProjectId': firebaseProjectId,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Converts to Firestore REST API `fields` payload for PATCH/POST requests.
  Map<String, dynamic> toFirestoreFields() {
    return {
      'fields': {
        'host': {'stringValue': host},
        'port': {'integerValue': port.toString()},
        'username': {'stringValue': username},
        'password': {'stringValue': password},
        'fromEmail': {'stringValue': fromEmail},
        'fromName': {'stringValue': fromName},
        'useTls': {'booleanValue': useTls},
        'useSsl': {'booleanValue': useSsl},
        'supervisorEmails': {
          'arrayValue': {
            'values': [
              for (final email in supervisorEmails) {'stringValue': email}
            ]
          }
        },
      }
    };
  }
}

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Rolling file log for the Windows desktop process.
///
/// The native runner writes the same file before Dart starts:
/// `%LOCALAPPDATA%\ecuisine_mess\logs\app.log`.
///
/// Keep the 1 MB cap and three archives aligned with
/// `windows/runner/startup_log.cpp`.
class AppLog {
  AppLog._();

  static const String fileName = 'app.log';
  static const int defaultMaxBytes = 1024 * 1024;
  static const int keptArchives = 3;

  static String? _directoryPath;
  static int _maxBytes = defaultMaxBytes;

  static final RegExp _secretAssignment = RegExp(
    r'''\b(password|passwd|pin|supervisor_pin|token|rfid(?:[_-]?tag)?|authorization|secret|api[_-]?key)(\s*[:=]\s*)(?:"[^"]*"|'[^']*'|bearer\s+\S+|\S+)''',
    caseSensitive: false,
  );
  static final RegExp _bearer = RegExp(
    r'\bbearer\s+\S+',
    caseSensitive: false,
  );

  /// Directory that holds [fileName]. Tests pass [environment] and [tempPath].
  static String logDirectoryPath({
    Map<String, String>? environment,
    String? tempPath,
  }) {
    final env = environment ?? Platform.environment;
    final localAppData = env['LOCALAPPDATA']?.trim();
    if (localAppData != null && localAppData.isNotEmpty) {
      return p.join(localAppData, 'ecuisine_mess', 'logs');
    }
    final profile = env['USERPROFILE']?.trim();
    if (profile != null && profile.isNotEmpty) {
      return p.join(profile, 'AppData', 'Local', 'ecuisine_mess', 'logs');
    }
    return p.join(
      tempPath ?? Directory.systemTemp.path,
      'ecuisine_mess',
      'logs',
    );
  }

  /// Hides RFID values, tokens, PINs, and passwords before a line is stored.
  @visibleForTesting
  static String redact(String message) {
    final withoutAssignments = message.replaceAllMapped(_secretAssignment, (
      match,
    ) {
      return '${match[1]}${match[2]}[redacted]';
    });
    return withoutAssignments.replaceAll(_bearer, 'Bearer [redacted]');
  }

  /// Points later writes at [directoryPath]. Production leaves this unset.
  @visibleForTesting
  static void debugUseDirectory(String directoryPath, {int? maxBytes}) {
    _directoryPath = directoryPath;
    _maxBytes = maxBytes ?? defaultMaxBytes;
  }

  @visibleForTesting
  static void debugReset() {
    _directoryPath = null;
    _maxBytes = defaultMaxBytes;
  }

  /// Creates the log directory and records framework and platform errors.
  static void install() {
    _directoryPath ??= logDirectoryPath();
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      error('Flutter framework error', details.exception, details.stack);
      if (previous != null) {
        previous(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (object, stack) {
      error('Uncaught platform error', object, stack);
      return true;
    };
    info('log file ready');
  }

  static void info(String message) => _write('info', message);

  static void warning(String message) => _write('warning', message);

  static void error(String message, [Object? error, StackTrace? stack]) {
    final buffer = StringBuffer(message);
    if (error != null) {
      buffer.write(': $error');
    }
    if (stack != null) {
      buffer.write('\n$stack');
    }
    _write('error', buffer.toString());
  }

  static void _write(String level, String message) {
    try {
      final directory = Directory(_directoryPath ??= logDirectoryPath());
      directory.createSync(recursive: true);
      _rotate(directory);
      final file = File(p.join(directory.path, fileName));
      file.writeAsStringSync(
        _stamp(level, redact(message)),
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // A logging failure must not stop the counter from opening.
    }
  }

  static void _rotate(Directory directory) {
    final active = File(p.join(directory.path, fileName));
    if (!active.existsSync() || active.lengthSync() < _maxBytes) return;

    for (var index = keptArchives; index >= 1; index--) {
      final source = File(
        p.join(
          directory.path,
          index == 1 ? fileName : '$fileName.${index - 1}',
        ),
      );
      final target = File(p.join(directory.path, '$fileName.$index'));
      if (!source.existsSync()) continue;
      if (target.existsSync()) {
        target.deleteSync();
      }
      source.renameSync(target.path);
    }
  }

  static String _stamp(String level, String message) {
    final time = _timestamp(DateTime.now());
    final lines = message.split('\n');
    final buffer = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      final text = lines[i].replaceAll('\r', '');
      buffer
        ..write(i == 0 ? '$time $level $text' : '  $text')
        ..write('\r\n');
    }
    return buffer.toString();
  }

  static String _timestamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    String three(int value) => value.toString().padLeft(3, '0');
    return '${time.year.toString().padLeft(4, '0')}-'
        '${two(time.month)}-${two(time.day)}'
        'T${two(time.hour)}:${two(time.minute)}:${two(time.second)}.'
        '${three(time.millisecond)}';
  }
}

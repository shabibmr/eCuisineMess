import 'dart:convert';
import 'dart:io';

import 'package:ecuisine_mess/core/config/app_config.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:http/http.dart' as http;

/// Local MariaDB and API helpers for the installed Windows app.
class LocalMessServices {
  static bool hostIsLocal(String baseUrl) {
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null || !uri.hasScheme) return false;
    final host = uri.host.toLowerCase();
    return host == '127.0.0.1' || host == 'localhost';
  }

  /// `{exe dir}\tools\mess-service.ps1` when the Full Mess PC layout is installed.
  static String? scriptPath() {
    if (!Platform.isWindows) return null;
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final path = '$exeDir${Platform.pathSeparator}tools${Platform.pathSeparator}mess-service.ps1';
    if (File(path).existsSync()) return path;
    return null;
  }

  /// Offer a local start only for an installed exe talking to this PC.
  static bool get canOfferLocalStart {
    if (scriptPath() == null) return false;
    if (!sl.isRegistered<AppConfig>()) return false;
    return hostIsLocal(sl<AppConfig>().baseUrl);
  }

  static Future<bool> healthOk() async {
    if (!sl.isRegistered<AppConfig>()) return false;
    final uri = Uri.parse('${sl<AppConfig>().baseUrl}/api/v1/health');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      return body is Map && body['database'] == 'connected';
    } catch (_) {
      return false;
    }
  }

  static Future<bool> start() async {
    final script = scriptPath();
    if (script == null) return false;
    try {
      final result = await Process.run(
        'powershell.exe',
        [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-File',
          script,
          'start',
        ],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> pollHealth(Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await healthOk()) return true;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return healthOk();
  }
}

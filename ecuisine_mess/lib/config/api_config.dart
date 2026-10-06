import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _prefsKey = 'mess_api_base_url';
  static const defaultBaseUrl = 'http://127.0.0.1:8000';

  static String baseUrl = defaultBaseUrl;

  /// Load persisted API base URL. Call once before [runApp].
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null || saved.trim().isEmpty) {
      baseUrl = defaultBaseUrl;
      return;
    }
    try {
      baseUrl = _normalize(saved.trim());
    } catch (_) {
      baseUrl = defaultBaseUrl;
    }
  }

  /// Persist and apply a new base URL. Throws [ArgumentError] if invalid.
  static Future<void> setBaseUrl(String url) async {
    final normalized = _normalize(url.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, normalized);
    baseUrl = normalized;
  }

  static String _normalize(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw ArgumentError('URL must start with http:// or https://');
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}

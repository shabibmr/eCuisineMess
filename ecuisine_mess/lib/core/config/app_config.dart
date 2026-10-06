import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  AppConfig(this._prefs);

  final SharedPreferences _prefs;

  String _baseUrl = AppConstants.defaultApiBaseUrl;

  String get baseUrl => _baseUrl;

  /// Load persisted API base URL. Call once before [runApp].
  Future<void> load() async {
    final saved = _prefs.getString(AppConstants.apiBaseUrlPrefsKey);
    if (saved == null || saved.trim().isEmpty) {
      _baseUrl = AppConstants.defaultApiBaseUrl;
      return;
    }
    try {
      _baseUrl = normalize(saved.trim());
    } catch (_) {
      _baseUrl = AppConstants.defaultApiBaseUrl;
    }
  }

  /// Persist and apply a new base URL. Throws [ArgumentError] if invalid.
  Future<void> setBaseUrl(String url) async {
    final normalized = normalize(url.trim());
    await _prefs.setString(AppConstants.apiBaseUrlPrefsKey, normalized);
    _baseUrl = normalized;
  }

  static String normalize(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw ArgumentError('URL must start with http:// or https://');
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}

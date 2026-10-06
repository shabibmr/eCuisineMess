import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SessionLocalDataSource {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  SessionLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> readToken() async {
    final current = _prefs.getString(AppConstants.sessionTokenPrefsKey);
    if (current != null && current.isNotEmpty) return current;

    final legacy = _prefs.getString(AppConstants.legacyAuthTokenPrefsKey);
    if (legacy != null && legacy.isNotEmpty) {
      await _prefs.setString(AppConstants.sessionTokenPrefsKey, legacy);
      await _prefs.remove(AppConstants.legacyAuthTokenPrefsKey);
      return legacy;
    }
    return null;
  }

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(AppConstants.sessionTokenPrefsKey, token);
    await _prefs.remove(AppConstants.legacyAuthTokenPrefsKey);
  }

  @override
  Future<void> clearToken() async {
    await _prefs.remove(AppConstants.sessionTokenPrefsKey);
    await _prefs.remove(AppConstants.legacyAuthTokenPrefsKey);
  }
}

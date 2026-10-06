import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecuisine_mess/models/user.dart';
import 'package:ecuisine_mess/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _tokenKey = 'mess_auth_token';

  final ApiService _api = ApiService();

  AppUser? _user;
  String? _token;
  bool _ready = false;
  bool _busy = false;
  String? _error;

  AuthProvider() {
    ApiService.onUnauthorized = _handleUnauthorized;
  }

  AppUser? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null && _token != null;
  bool get ready => _ready;
  bool get busy => _busy;
  String? get error => _error;

  void _handleUnauthorized() {
    // Local clear only — do not call POST /auth/logout.
    _token = null;
    _user = null;
    ApiService.authToken = null;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) => prefs.remove(_tokenKey));
  }

  Future<void> _clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _token = null;
    _user = null;
    ApiService.authToken = null;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_tokenKey);
    if (saved == null || saved.isEmpty) {
      _ready = true;
      notifyListeners();
      return;
    }
    try {
      final me = await _api.fetchMe(saved);
      _token = saved;
      _user = me;
      ApiService.authToken = saved;
    } catch (_) {
      await prefs.remove(_tokenKey);
      _token = null;
      _user = null;
      ApiService.authToken = null;
    }
    _ready = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.login(username, password);
      _token = result['token'] as String;
      _user = result['user'] as AppUser;
      ApiService.authToken = _token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);
      _busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final t = _token;
    if (t != null) {
      try {
        await _api.logout(t);
      } catch (_) {}
    }
    await _clearLocalSession();
  }
}

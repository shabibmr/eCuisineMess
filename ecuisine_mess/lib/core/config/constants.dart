class AppConstants {
  static const String appName = 'eCuisine Mess';
  static const String defaultApiBaseUrl = 'http://127.0.0.1:8000';
  static const String apiBaseUrlPrefsKey = 'mess_api_base_url';
  static const String sessionTokenPrefsKey = 'mess_session_token';
  static const String printerNamePrefsKey = 'mess_printer_name';
  static const String printerModePrefsKey = 'mess_printer_mode';
  static const String printerWidthPrefsKey = 'mess_printer_width_mm';
  /// Pre-FE-0 key; still read once for session restore migration.
  static const String legacyAuthTokenPrefsKey = 'mess_auth_token';
  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration healthTimeout = Duration(seconds: 3);
  static const String defaultFirebaseProjectId = 'ecuisine-mess';
  static const String firestoreSmtpDocPath = 'settings/smtp';
  static const String smtpSettingsCachePrefsKey = 'mess_smtp_settings_cache';
  static const String firebaseProjectIdPrefsKey = 'mess_firebase_project_id';
}

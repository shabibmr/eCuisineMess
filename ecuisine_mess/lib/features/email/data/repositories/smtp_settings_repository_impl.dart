import 'dart:convert';
import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/features/email/data/datasources/smtp_firestore_datasource.dart';
import 'package:ecuisine_mess/features/email/data/models/smtp_settings_model.dart';
import 'package:ecuisine_mess/features/email/domain/entities/smtp_settings.dart';
import 'package:ecuisine_mess/features/email/domain/repositories/smtp_settings_repository.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmtpSettingsRepositoryImpl implements SmtpSettingsRepository {
  SmtpSettingsRepositoryImpl({
    required SmtpFirestoreDataSource firestoreDataSource,
    required SharedPreferences prefs,
    Logger? logger,
  })  : _firestoreDataSource = firestoreDataSource,
        _prefs = prefs,
        _logger = logger ?? Logger() {
    _loadFromCache();
  }

  final SmtpFirestoreDataSource _firestoreDataSource;
  final SharedPreferences _prefs;
  final Logger _logger;

  SmtpSettings _currentSettings = const SmtpSettings();

  @override
  SmtpSettings get currentSettings => _currentSettings;

  void _loadFromCache() {
    try {
      final cachedJson = _prefs.getString(AppConstants.smtpSettingsCachePrefsKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final map = jsonDecode(cachedJson) as Map<String, dynamic>;
        _currentSettings = SmtpSettingsModel.fromJson(map);
        _logger.d('Loaded SMTP settings from local cache.');
      }
    } catch (e) {
      _logger.w('Failed to parse cached SMTP settings: $e');
    }
  }

  @override
  Future<SmtpSettings> getSettings() async {
    final customProjectId = _prefs.getString(AppConstants.firebaseProjectIdPrefsKey);
    try {
      final remoteModel = await _firestoreDataSource.getSmtpSettings(
        projectId: customProjectId,
      );
      _currentSettings = remoteModel;
      await _prefs.setString(
        AppConstants.smtpSettingsCachePrefsKey,
        jsonEncode(remoteModel.toJson()),
      );
      _logger.i('Fetched and cached fresh SMTP settings from Firestore.');
      return _currentSettings;
    } catch (e) {
      _logger.w('Could not fetch from Firestore ($e); using cached settings.');
      return _currentSettings;
    }
  }

  @override
  Future<void> saveSettings(SmtpSettings settings) async {
    final model = SmtpSettingsModel.fromEntity(settings);
    final customProjectId = _prefs.getString(AppConstants.firebaseProjectIdPrefsKey);

    // Save to Firestore directly
    await _firestoreDataSource.saveSmtpSettings(
      model,
      projectId: customProjectId,
    );

    // Update in-memory & local cache
    _currentSettings = model;
    await _prefs.setString(
      AppConstants.smtpSettingsCachePrefsKey,
      jsonEncode(model.toJson()),
    );
    _logger.i('Persisted SMTP settings to Firestore and local cache.');
  }
}

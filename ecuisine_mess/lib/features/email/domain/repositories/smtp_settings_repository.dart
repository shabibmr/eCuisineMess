import 'package:ecuisine_mess/features/email/domain/entities/smtp_settings.dart';

/// Repository interface for fetching and persisting SMTP server settings.
abstract class SmtpSettingsRepository {
  /// Fetches SMTP settings from Firestore directly, falling back to local cache if offline.
  Future<SmtpSettings> getSettings();

  /// Saves SMTP settings directly to Firestore and updates local cache.
  Future<void> saveSettings(SmtpSettings settings);

  /// Synchronously returns current in-memory / cached settings.
  SmtpSettings get currentSettings;
}

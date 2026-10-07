import 'package:ecuisine_mess/features/email/domain/entities/email_attachment.dart';
import 'package:ecuisine_mess/features/email/domain/entities/email_send_result.dart';

/// Abstract contract for the Email Service Module.
///
/// Can be invoked anywhere in the Flutter app via:
/// 1. `context.read<EmailService>()` (inside the widget tree)
/// 2. `EmailService.current` (outside the widget tree / global helpers)
abstract class EmailService {
  /// Global static accessor allowing invocation from anywhere without BuildContext.
  static EmailService? _instance;
  static EmailService get current {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'EmailService.current accessed before initialization. '
        'Ensure EmailService is provided or set on app launch.',
      );
    }
    return instance;
  }

  static set current(EmailService instance) {
    _instance = instance;
  }

  /// Sends a general-purpose email asynchronously with optional attachments.
  Future<EmailSendResult> sendEmail({
    required List<String> recipients,
    List<String>? cc,
    List<String>? bcc,
    required String subject,
    String? bodyText,
    String? bodyHtml,
    List<EmailAttachment>? attachments,
  });

  /// Convenience method for sending automated reports with branded eCuisine HTML template
  /// and attached report files (such as pipe-delimited CSVs).
  Future<EmailSendResult> sendReportEmail({
    required List<String> recipients,
    required String reportTitle,
    required String periodDescription,
    required List<EmailAttachment> attachments,
    String? customNotes,
  });

  /// Verifies SMTP connectivity and credentials by dispatching a test email.
  Future<EmailSendResult> testConnection({
    required String testRecipient,
  });
}

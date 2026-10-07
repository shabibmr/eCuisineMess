import 'dart:io';
import 'package:ecuisine_mess/features/email/domain/entities/email_attachment.dart';
import 'package:ecuisine_mess/features/email/domain/entities/email_send_result.dart';
import 'package:ecuisine_mess/features/email/domain/entities/smtp_settings.dart';
import 'package:ecuisine_mess/features/email/domain/repositories/smtp_settings_repository.dart';
import 'package:ecuisine_mess/features/email/domain/services/email_service.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Concrete implementation of EmailService utilizing package:mailer.
/// Provides non-blocking asynchronous email transmission directly from the Flutter client.
class MailerEmailServiceImpl implements EmailService {
  MailerEmailServiceImpl({
    required SmtpSettingsRepository settingsRepository,
    Logger? logger,
  })  : _settingsRepository = settingsRepository,
        _logger = logger ?? Logger() {
    // Register as the global instance for invocation anywhere in the app
    EmailService.current = this;
  }

  final SmtpSettingsRepository _settingsRepository;
  final Logger _logger;

  SmtpServer _buildSmtpServer(SmtpSettings settings) {
    return SmtpServer(
      settings.host.trim(),
      port: settings.port,
      ssl: settings.useSsl,
      allowInsecure: !settings.useTls && !settings.useSsl,
      ignoreBadCertificate: false,
      username: settings.username.trim().isNotEmpty
          ? settings.username.trim()
          : null,
      password: settings.password.trim().isNotEmpty
          ? settings.password.trim()
          : null,
    );
  }

  @override
  Future<EmailSendResult> sendEmail({
    required List<String> recipients,
    List<String>? cc,
    List<String>? bcc,
    required String subject,
    String? bodyText,
    String? bodyHtml,
    List<EmailAttachment>? attachments,
  }) async {
    final cleanRecipients = recipients
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .toList();

    if (cleanRecipients.isEmpty) {
      _logger.w('Email sending aborted: recipient list is empty.');
      return EmailSendResult.failure('Recipient list is empty');
    }

    final settings = await _settingsRepository.getSettings();
    if (!settings.isConfigured) {
      const msg = 'SMTP Server is not configured. Please set host and sender email in Settings.';
      _logger.w(msg);
      return EmailSendResult.failure(msg);
    }

    final smtpServer = _buildSmtpServer(settings);
    final message = Message()
      ..from = Address(settings.fromEmail.trim(), settings.fromName.trim())
      ..recipients.addAll(cleanRecipients)
      ..subject = subject;

    if (cc != null && cc.isNotEmpty) {
      message.ccRecipients.addAll(cc.map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    if (bcc != null && bcc.isNotEmpty) {
      message.bccRecipients.addAll(bcc.map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    if (bodyText != null && bodyText.isNotEmpty) {
      message.text = bodyText;
    }
    if (bodyHtml != null && bodyHtml.isNotEmpty) {
      message.html = bodyHtml;
    }

    if (attachments != null && attachments.isNotEmpty) {
      for (final att in attachments) {
        if (att.filePath != null) {
          final file = File(att.filePath!);
          if (file.existsSync()) {
            message.attachments.add(
              FileAttachment(
                file,
                fileName: att.fileName,
                contentType: att.mimeType,
              ),
            );
          } else {
            _logger.w('Attachment file does not exist at path: ${att.filePath}');
          }
        } else if (att.bytes != null) {
          message.attachments.add(
            StreamAttachment(
              Stream.value(att.bytes!),
              att.mimeType ?? 'application/octet-stream',
              fileName: att.fileName,
            ),
          );
        }
      }
    }

    _logger.i('Asynchronously sending email "$subject" to $cleanRecipients via ${settings.host}');

    try {
      final sendReport = await send(message, smtpServer);
      _logger.i('Email sent successfully. Result: ${sendReport.toString()}');
      return EmailSendResult.success(messageId: sendReport.toString());
    } on MailerException catch (e) {
      _logger.e('MailerException occurred while sending email: ${e.message}', error: e);
      final problemDetails = e.problems.map((p) => '${p.code}: ${p.msg}').join('; ');
      return EmailSendResult.failure(
        problemDetails.isNotEmpty ? problemDetails : e.message,
      );
    } catch (e, stack) {
      _logger.e('Unexpected error sending email: $e', error: e, stackTrace: stack);
      return EmailSendResult.failure(e.toString());
    }
  }

  @override
  Future<EmailSendResult> sendReportEmail({
    required List<String> recipients,
    required String reportTitle,
    required String periodDescription,
    required List<EmailAttachment> attachments,
    String? customNotes,
  }) async {
    final nowFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final subject = 'eCuisine Report: $reportTitle ($periodDescription)';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; color: #1e293b; margin: 0; padding: 24px; }
    .card { background-color: #ffffff; border-radius: 8px; border: 1px solid #e2e8f0; max-width: 600px; margin: 0 auto; overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
    .header { background: #0f172a; color: #ffffff; padding: 20px 24px; }
    .header h1 { margin: 0; font-size: 18px; font-weight: 600; letter-spacing: 0.5px; }
    .header p { margin: 4px 0 0 0; color: #94a3b8; font-size: 13px; }
    .body { padding: 24px; }
    .meta-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    .meta-table td { padding: 8px 0; font-size: 14px; border-bottom: 1px solid #f1f5f9; }
    .meta-table td.label { color: #64748b; width: 140px; font-weight: 500; }
    .meta-table td.value { color: #0f172a; font-weight: 600; }
    .notes { background-color: #f1f5f9; border-left: 4px solid #3b82f6; padding: 12px 16px; border-radius: 4px; font-size: 14px; margin-bottom: 20px; }
    .attachments-box { background-color: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 6px; padding: 12px 16px; font-size: 13px; color: #475569; }
    .footer { text-align: center; padding: 16px; font-size: 12px; color: #94a3b8; }
  </style>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1>eCuisine Mess Billing & Management</h1>
      <p>Automated Operational Report Dispatch</p>
    </div>
    <div class="body">
      <table class="meta-table">
        <tr>
          <td class="label">Report:</td>
          <td class="value">$reportTitle</td>
        </tr>
        <tr>
          <td class="label">Period / Filter:</td>
          <td class="value">$periodDescription</td>
        </tr>
        <tr>
          <td class="label">Generated At:</td>
          <td class="value">$nowFormatted</td>
        </tr>
      </table>

      ${customNotes != null && customNotes.trim().isNotEmpty ? '''
      <div class="notes">
        <strong>Supervisor Note:</strong><br>
        $customNotes
      </div>
      ''' : ''}

      <div class="attachments-box">
        <strong>Attached Report(s):</strong><br>
        ${attachments.map((a) => '• ${a.fileName}').join('<br>')}
        <br><br>
        <em>Note: CSV reports use standard pipe (|) delimiter with UTF-8 encoding.</em>
      </div>
    </div>
    <div class="footer">
      This is an automated operational email sent from the eCuisine Mess Counter Client.
    </div>
  </div>
</body>
</html>
''';

    final textContent = '''
eCuisine Mess Billing & Management — Operational Report
Report: $reportTitle
Period: $periodDescription
Generated At: $nowFormatted
${customNotes != null && customNotes.trim().isNotEmpty ? 'Notes: $customNotes\n' : ''}
Attachments: ${attachments.map((a) => a.fileName).join(', ')}
''';

    return sendEmail(
      recipients: recipients,
      subject: subject,
      bodyText: textContent,
      bodyHtml: htmlContent,
      attachments: attachments,
    );
  }

  @override
  Future<EmailSendResult> testConnection({
    required String testRecipient,
  }) async {
    const subject = 'eCuisine Mess — SMTP Test Verification';
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final text = 'This is a test email sent from the eCuisine Mess Client at $now to verify SMTP settings.';
    final html = '''
<div style="font-family: sans-serif; padding: 20px;">
  <h2 style="color: #0f172a;">SMTP Configuration Test Successful</h2>
  <p>Your SMTP mail configuration in eCuisine Mess is working properly.</p>
  <p><small>Timestamp: $now</small></p>
</div>
''';

    return sendEmail(
      recipients: [testRecipient],
      subject: subject,
      bodyText: text,
      bodyHtml: html,
    );
  }
}

import 'package:ecuisine_mess/features/email/domain/entities/email_attachment.dart';
import 'package:ecuisine_mess/features/email/domain/repositories/smtp_settings_repository.dart';
import 'package:ecuisine_mess/features/email/domain/services/email_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showEmailReportDialog({
  required BuildContext context,
  required String reportTitle,
  required String periodDescription,
  required Future<List<int>> Function() fetchCsvBytes,
  required String suggestedFileName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return EmailReportDialog(
        reportTitle: reportTitle,
        periodDescription: periodDescription,
        fetchCsvBytes: fetchCsvBytes,
        suggestedFileName: suggestedFileName,
      );
    },
  );
}

class EmailReportDialog extends StatefulWidget {
  const EmailReportDialog({
    super.key,
    required this.reportTitle,
    required this.periodDescription,
    required this.fetchCsvBytes,
    required this.suggestedFileName,
  });

  final String reportTitle;
  final String periodDescription;
  final Future<List<int>> Function() fetchCsvBytes;
  final String suggestedFileName;

  @override
  State<EmailReportDialog> createState() => _EmailReportDialogState();
}

class _EmailReportDialogState extends State<EmailReportDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recipientsController;
  late final TextEditingController _notesController;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final settingsRepo = context.read<SmtpSettingsRepository>();
    final defaultRecipients = settingsRepo.currentSettings.supervisorEmails;
    _recipientsController = TextEditingController(
      text: defaultRecipients.join(', '),
    );
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _recipientsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    final recipients = _recipientsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one recipient email address.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      // Fetch fresh CSV bytes
      final bytes = await widget.fetchCsvBytes();

      if (!mounted) return;

      final attachment = EmailAttachment.fromBytes(
        fileName: widget.suggestedFileName,
        bytes: bytes,
        mimeType: 'text/csv',
      );

      final emailService = context.read<EmailService>();
      final result = await emailService.sendReportEmail(
        recipients: recipients,
        reportTitle: widget.reportTitle,
        periodDescription: widget.periodDescription,
        attachments: [attachment],
        customNotes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report email successfully sent to ${recipients.join(', ')}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: ${result.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error preparing report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.send_outlined, color: Colors.blue),
          const SizedBox(width: 8),
          Text('Email ${widget.reportTitle}'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dispatching report with pipe-delimited CSV attachment for: ${widget.periodDescription}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recipientsController,
                decoration: const InputDecoration(
                  labelText: 'Recipient Emails (Comma-separated)',
                  hintText: 'supervisor@ecuisine.ae, auditor@ecuisine.ae',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                  isDense: true,
                ),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Recipient required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Optional Supervisor Note',
                  hintText: 'e.g. Please review breakfast attendance variance.',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Attached: ${widget.suggestedFileName}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: _sending
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send, size: 16),
          label: const Text('Send Email'),
          onPressed: _sending ? null : _send,
        ),
      ],
    );
  }
}

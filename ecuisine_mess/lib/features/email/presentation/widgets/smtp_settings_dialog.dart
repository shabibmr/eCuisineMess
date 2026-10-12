import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/features/email/domain/entities/smtp_settings.dart';
import 'package:ecuisine_mess/features/email/presentation/cubit/smtp_settings_cubit.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:ecuisine_mess/shared/widgets/inputs/app_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showSmtpSettingsDialog(BuildContext context) =>
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<SmtpSettingsCubit>(),
        child: const SmtpSettingsDialog(),
      ),
    );

class SmtpSettingsDialog extends StatefulWidget {
  const SmtpSettingsDialog({super.key});

  @override
  State<SmtpSettingsDialog> createState() => _SmtpSettingsDialogState();
}

class _SmtpSettingsDialogState extends State<SmtpSettingsDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _fromEmailController;
  late final TextEditingController _fromNameController;
  late final TextEditingController _supervisorEmailsController;
  late final TextEditingController _firebaseProjectController;
  late final TextEditingController _testRecipientController;

  bool _useTls = true;
  bool _useSsl = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SmtpSettingsCubit>().state.settings;

    _hostController = TextEditingController(text: settings.host);
    _portController = TextEditingController(text: settings.port.toString());
    _usernameController = TextEditingController(text: settings.username);
    _passwordController = TextEditingController(text: settings.password);
    _fromEmailController = TextEditingController(text: settings.fromEmail);
    _fromNameController = TextEditingController(text: settings.fromName);
    _supervisorEmailsController = TextEditingController(
      text: settings.supervisorEmails.join(', '),
    );
    _firebaseProjectController = TextEditingController(
      text: settings.firebaseProjectId.isNotEmpty
          ? settings.firebaseProjectId
          : AppConstants.defaultFirebaseProjectId,
    );
    _testRecipientController = TextEditingController();

    _useTls = settings.useTls;
    _useSsl = settings.useSsl;
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _fromEmailController.dispose();
    _fromNameController.dispose();
    _supervisorEmailsController.dispose();
    _firebaseProjectController.dispose();
    _testRecipientController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final supervisors = _supervisorEmailsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final newSettings = SmtpSettings(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 587,
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
      fromEmail: _fromEmailController.text.trim(),
      fromName: _fromNameController.text.trim(),
      useTls: _useTls,
      useSsl: _useSsl,
      supervisorEmails: supervisors,
      firebaseProjectId: _firebaseProjectController.text.trim(),
      updatedAt: DateTime.now(),
    );

    context.read<SmtpSettingsCubit>().saveSettings(newSettings);
  }

  void _testConnection() {
    final recipient = _testRecipientController.text.trim();
    if (recipient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a test recipient email address.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    context.read<SmtpSettingsCubit>().testConnection(recipient);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SmtpSettingsCubit, SmtpSettingsState>(
      listener: (context, state) {
        if (state.status == SmtpSettingsStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'Settings saved.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.status == SmtpSettingsStatus.error &&
            state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state.status == SmtpSettingsStatus.saving;
        final isTesting = state.testStatus == SmtpTestStatus.testing;

        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.email_outlined, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Email & SMTP Settings'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Reload from Firestore',
                onPressed: isSaving ? null : () => context.read<SmtpSettingsCubit>().loadSettings(),
              ),
            ],
          ),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SMTP Configuration (Stored in Cloud Firestore settings/smtp):',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _hostController,
                            decoration: const InputDecoration(
                              labelText: 'SMTP Host',
                              hintText: 'e.g. smtp.gmail.com',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Host required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _portController,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              hintText: '587',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'SMTP Username / Login',
                              hintText: 'Username or email',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppPasswordField(
                            controller: _passwordController,
                            label: 'Password / App Password',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fromEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Sender Email (From)',
                              hintText: 'e.g. reports@ecuisine.ae',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'From email required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _fromNameController,
                            decoration: const InputDecoration(
                              labelText: 'Sender Display Name',
                              hintText: 'eCuisine Mess System',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('STARTTLS', style: TextStyle(fontSize: 13)),
                            value: _useTls,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setState(() => _useTls = v ?? true),
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('SSL Direct', style: TextStyle(fontSize: 13)),
                            value: _useSsl,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) => setState(() => _useSsl = v ?? false),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Supervisor Notification List (Auto-Reports):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _supervisorEmailsController,
                      decoration: const InputDecoration(
                        labelText: 'Supervisor Emails (Comma-separated)',
                        hintText: 'manager@ecuisine.ae, auditor@ecuisine.ae',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Cloud Firestore Project:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _firebaseProjectController,
                      decoration: const InputDecoration(
                        labelText: 'Firebase Project ID',
                        hintText: 'ecuisine-mess',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const Divider(height: 24),
                    const Text(
                      'Test SMTP Connection:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _testRecipientController,
                            decoration: const InputDecoration(
                              labelText: 'Test Recipient Address',
                              hintText: 'your-email@example.com',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: isTesting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_outlined, size: 16),
                          label: const Text('Test'),
                          onPressed: isTesting ? null : _testConnection,
                        ),
                      ],
                    ),
                    if (state.testMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        state.testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: state.testStatus == SmtpTestStatus.success
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            AppSaveButton(
              label: 'Save to Firestore',
              loadingLabel: 'Saving...',
              isLoading: isSaving,
              icon: Icons.save,
              onPressed: _save,
            ),
          ],
        );
      },
    );
  }
}

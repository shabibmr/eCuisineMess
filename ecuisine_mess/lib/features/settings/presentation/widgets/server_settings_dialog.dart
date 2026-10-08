import 'package:ecuisine_mess/core/config/constants.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/services/local_mess_services.dart';
import 'package:ecuisine_mess/core/services/mess_server_guard.dart';
import 'package:ecuisine_mess/features/settings/presentation/cubit/server_settings_cubit.dart';
import 'package:ecuisine_mess/shared/widgets/buttons/app_save_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showServerSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return BlocProvider(
        create: (_) => sl<ServerSettingsCubit>(),
        child: const _ServerSettingsDialog(),
      );
    },
  );
}

class _ServerSettingsDialog extends StatefulWidget {
  const _ServerSettingsDialog();

  @override
  State<_ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<_ServerSettingsDialog> {
  late final TextEditingController _urlController;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: context.read<ServerSettingsCubit>().state.draftUrl,
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ServerSettingsCubit, ServerSettingsState>(
      listener: (context, state) {
        if (state.status == ServerSettingsStatus.ok) {
          Navigator.pop(context);
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        }
      },
      builder: (context, state) {
        final testing = state.status == ServerSettingsStatus.testing;
        final errorText =
            state.status == ServerSettingsStatus.error ? state.message : null;

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.blue),
              SizedBox(width: 8),
              Text('Backend API Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the Python FastAPI or Frappe Server URL:',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                onChanged: context.read<ServerSettingsCubit>().urlChanged,
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: AppConstants.defaultApiBaseUrl,
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
              if (testing) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
            ],
          ),
          actions: [
            if (LocalMessServices.canOfferLocalStart)
              TextButton(
                onPressed: testing || _starting
                    ? null
                    : () async {
                        setState(() => _starting = true);
                        try {
                          await startInstalledMessServer(context);
                        } finally {
                          if (mounted) setState(() => _starting = false);
                        }
                      },
                child: const Text('Start server'),
              ),
            TextButton(
              onPressed: testing || _starting ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            AppSaveButton(
              label: 'Save & Apply',
              loadingLabel: 'Applying...',
              isLoading: testing,
              onPressed: _starting
                  ? null
                  : () => context.read<ServerSettingsCubit>().saveAndApply(),
            ),
          ],
        );
      },
    );
  }
}

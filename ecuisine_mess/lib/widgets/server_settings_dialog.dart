import 'package:flutter/material.dart';
import 'package:ecuisine_mess/config/api_config.dart';

/// Shared dialog for Login and MainLayout. Saves via [ApiConfig.setBaseUrl].
Future<void> showServerSettingsDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => const _LegacyServerSettingsDialog(),
  );
}

class _LegacyServerSettingsDialog extends StatefulWidget {
  const _LegacyServerSettingsDialog();

  @override
  State<_LegacyServerSettingsDialog> createState() =>
      _LegacyServerSettingsDialogState();
}

class _LegacyServerSettingsDialogState
    extends State<_LegacyServerSettingsDialog> {
  late final TextEditingController _urlController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ApiConfig.setBaseUrl(_urlController.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API URL updated to: ${ApiConfig.baseUrl}')),
        );
      }
    } on ArgumentError catch (e) {
      setState(() => _errorText = e.message?.toString() ?? 'Invalid URL');
    } catch (e) {
      setState(() => _errorText = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
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
            decoration: InputDecoration(
              labelText: 'API Base URL',
              hintText: ApiConfig.defaultBaseUrl,
              border: const OutlineInputBorder(),
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save & Apply'),
        ),
      ],
    );
  }
}

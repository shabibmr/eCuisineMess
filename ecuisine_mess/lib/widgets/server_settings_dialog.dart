import 'package:flutter/material.dart';
import 'package:ecuisine_mess/config/api_config.dart';

/// Shared dialog for Login and MainLayout. Saves via [ApiConfig.setBaseUrl].
Future<void> showServerSettingsDialog(BuildContext context) async {
  final urlController = TextEditingController(text: ApiConfig.baseUrl);
  String? errorText;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
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
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'API Base URL',
                    hintText: ApiConfig.defaultBaseUrl,
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiConfig.setBaseUrl(urlController.text.trim());
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('API URL updated to: ${ApiConfig.baseUrl}')),
                      );
                    }
                  } on ArgumentError catch (e) {
                    setLocal(() => errorText = e.message?.toString() ?? 'Invalid URL');
                  } catch (e) {
                    setLocal(() => errorText = e.toString());
                  }
                },
                child: const Text('Save & Apply'),
              ),
            ],
          );
        },
      );
    },
  );
  urlController.dispose();
}

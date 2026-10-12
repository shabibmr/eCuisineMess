import 'package:ecuisine_mess/shared/widgets/feedback/app_alert_banner.dart';
import 'package:flutter/material.dart';

class RejectBanner extends StatelessWidget {
  const RejectBanner({
    super.key,
    required this.message,
    this.showOverride = false,
    this.onOverride,
  });

  final String message;
  final bool showOverride;
  final VoidCallback? onOverride;

  @override
  Widget build(BuildContext context) {
    return AppAlertBanner.error(
      title: 'Entitlement Rejected',
      message: message,
      margin: const EdgeInsets.only(bottom: 20),
      action: showOverride && onOverride != null
          ? ElevatedButton.icon(
              onPressed: onOverride,
              icon: const Icon(Icons.lock_open, size: 16),
              label: const Text('Supervisor Override (F8)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
              ),
            )
          : null,
    );
  }
}

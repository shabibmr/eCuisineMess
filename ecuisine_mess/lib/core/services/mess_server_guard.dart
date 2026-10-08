import 'dart:async';

import 'package:ecuisine_mess/core/services/local_mess_services.dart';
import 'package:ecuisine_mess/core/services/mess_server_signals.dart';
import 'package:flutter/material.dart';

/// Handles recovery when the installed local API becomes unavailable at runtime.
///
/// Initial startup is coordinated separately; this widget does not run a
/// health check or invoke PowerShell merely because the app was constructed.
class MessServerGuard extends StatefulWidget {
  const MessServerGuard({required this.child, super.key});

  final Widget child;

  @override
  State<MessServerGuard> createState() => _MessServerGuardState();
}

class _MessServerGuardState extends State<MessServerGuard> {
  StreamSubscription<void>? _lost;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _lost = MessServerSignals.instance.onConnectionLost.listen((_) {
      unawaited(_maybePrompt());
    });
  }

  @override
  void dispose() {
    _lost?.cancel();
    super.dispose();
  }

  Future<void> _maybePrompt() async {
    if (!mounted || _busy) return;
    if (!LocalMessServices.canOfferLocalStart) return;

    _busy = true;
    try {
      if (await LocalMessServices.healthOk()) return;
      if (!mounted) return;

      final start = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            content: const Text('Mess server is not running. Start it?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Yes'),
              ),
            ],
          );
        },
      );

      if (start != true || !mounted) return;

      final started = await LocalMessServices.start();
      final ok = started &&
          await LocalMessServices.pollHealth(const Duration(seconds: 30));

      if (!ok && mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              content: const Text('Restart the PC or contact support.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Settings-dialog action. Starts the installed services without changing the
/// configured base URL.
Future<void> startInstalledMessServer(BuildContext context) async {
  if (!LocalMessServices.canOfferLocalStart) return;
  if (await LocalMessServices.healthOk()) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mess server is running.')),
    );
    return;
  }

  final started = await LocalMessServices.start();
  final ok =
      started && await LocalMessServices.pollHealth(const Duration(seconds: 30));

  if (!context.mounted) return;

  if (!ok) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: const Text('Restart the PC or contact support.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Mess server is running.')),
  );
}

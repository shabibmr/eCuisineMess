import 'dart:async';

import 'package:ecuisine_mess/core/services/local_mess_services.dart';
import 'package:ecuisine_mess/core/services/mess_server_signals.dart';
import 'package:flutter/material.dart';

/// Asks to start the local MariaDB and API services when this PC's server is down.
class MessServerGuard extends StatefulWidget {
  const MessServerGuard({required this.child, super.key});

  final Widget child;

  @override
  State<MessServerGuard> createState() => _MessServerGuardState();
}

class _MessServerGuardState extends State<MessServerGuard> {
  final GlobalKey<NavigatorState> _dialogNavKey = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _lost;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _lost = MessServerSignals.instance.onConnectionLost.listen((_) {
      _maybePrompt();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
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
      final start = await _ask(
        'Mess server is not running. Start it?',
        confirm: true,
      );
      if (start != true || !mounted) return;
      final ok = await _startAndWait();
      if (!ok && mounted) {
        await _ask('Restart the PC or contact support.', confirm: false);
      }
    } finally {
      _busy = false;
    }
  }

  Future<bool> _startAndWait() async {
    final started = await LocalMessServices.start();
    if (!started) return false;
    return LocalMessServices.pollHealth(const Duration(seconds: 30));
  }

  Future<bool?> _ask(String message, {required bool confirm}) {
    final nav = _dialogNavKey.currentState;
    if (nav == null) return Future<bool?>.value(false);
    return showDialog<bool>(
      context: nav.context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            if (confirm)
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirm ? 'Yes' : 'OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Navigator(
          key: _dialogNavKey,
          onGenerateRoute: (settings) {
            return PageRouteBuilder<void>(
              opaque: false,
              pageBuilder: (_, _, _) => const IgnorePointer(
                child: SizedBox.expand(),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Settings-dialog action. Starts the installed services without changing the base URL.
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
  final ok = started && await LocalMessServices.pollHealth(const Duration(seconds: 30));
  if (!context.mounted) return;
  if (!ok) {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const Text('Restart the PC or contact support.'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
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

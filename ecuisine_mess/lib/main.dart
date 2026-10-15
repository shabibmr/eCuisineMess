import 'dart:async';
import 'dart:io';

import 'package:ecuisine_mess/app.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/logging/app_log.dart';
import 'package:ecuisine_mess/core/services/firebase_initializer.dart';
import 'package:ecuisine_mess/core/services/startup_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Set after [runApp] so a failure before the window exits with a log line.
var _uiStarted = false;

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppLog.install();
      AppLog.info('Flutter binding ready');
      await FirebaseInitializer.initialize();
      AppLog.info('Firebase initializer finished');
      _installErrorWidget();
      await configureDependencies();
      AppLog.info('Dependencies configured');
      runApp(const ECuisineMessApp());
      _uiStarted = true;
      AppLog.info('UI started');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_startAfterFirstFrame());
      });
    },
    (error, stack) {
      AppLog.error('Uncaught error', error, stack);
      debugPrint('Uncaught error: $error\n$stack');
      if (!_uiStarted) {
        exit(1);
      }
    },
  );
}

Future<void> _startAfterFirstFrame() async {
  try {
    AppLog.info('Startup coordinator begin');
    await StartupCoordinator.start();
    AppLog.info('Startup coordinator finished');
  } catch (error, stack) {
    AppLog.error('Startup coordinator failed', error, stack);
  }
}

void _installErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 36),
              const SizedBox(height: 8),
              Text(
                'Something went wrong rendering this view.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade900,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                details.exceptionAsString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.red.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  };
}

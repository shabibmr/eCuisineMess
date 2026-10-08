import 'dart:async';

import 'package:ecuisine_mess/app.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/services/firebase_initializer.dart';
import 'package:ecuisine_mess/core/services/startup_coordinator.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseInitializer.initialize();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
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

  await configureDependencies();

  runApp(const ECuisineMessApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(StartupCoordinator.start());
  });
}

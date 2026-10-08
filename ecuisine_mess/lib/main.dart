import 'dart:async';

import 'package:ecuisine_mess/app.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/services/startup_coordinator.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  runApp(const ECuisineMessApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(StartupCoordinator.start());
  });
}

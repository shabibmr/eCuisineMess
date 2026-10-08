import 'package:ecuisine_mess/app.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  runApp(const ECuisineMessApp());

  WidgetsBinding.instance.addPostFrameCallback((_) {
    sl<AuthBloc>().add(const AuthStarted());
  });
}

/// Initializes Firebase after the first Flutter frame is available.
///
/// Firebase is required by optional cloud-backed features, not by the local
/// application startup path. Failure is logged so cloud features can report
/// their own errors without preventing the desktop shell from rendering.
Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized.');
  } catch (e, stack) {
    debugPrint('Firebase initialization warning: $e\n$stack');
  }
}

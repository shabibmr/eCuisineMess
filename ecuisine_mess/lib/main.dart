import 'package:ecuisine_mess/app.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ecuisine_mess/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('Firebase initialization warning: $e\n$stack');
  }
  await configureDependencies();
  sl<AuthBloc>().add(const AuthStarted());
  runApp(const ECuisineMessApp());
}

import 'dart:async';

import 'package:ecuisine_mess/core/services/firebase_initializer.dart';
import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';

/// Dispatches non-critical startup work after the Flutter shell is rendered.
///
/// The local Windows services are installed and managed independently by the
/// installer. Service recovery remains a runtime concern and is handled by
/// [MessServerGuard] when a real API connection loss occurs.
class StartupCoordinator {
  StartupCoordinator._();

  static Future<void> start() async {
    // Firebase is non-critical for local operation, but initialize it in the
    // background so cloud-backed features can use the native Firestore client.
    unawaited(FirebaseInitializer.initialize());
    sl<AuthBloc>().add(const AuthStarted());
  }
}

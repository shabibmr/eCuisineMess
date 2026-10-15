import 'dart:async';

import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/services/device_presence_service.dart';
import 'package:ecuisine_mess/core/services/expiry_service.dart';
import 'package:ecuisine_mess/core/services/firebase_initializer.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';

/// Dispatches non-critical startup work after the Flutter shell is rendered.
///
/// The local Windows services are installed and managed independently by the
/// installer. Service recovery remains a runtime concern and is handled by
/// [MessServerGuard] when a real API connection loss occurs.
class StartupCoordinator {
  StartupCoordinator._();

  static Future<void> start() async {
    // Ensure Firebase is initialized for cloud-backed features.
    await FirebaseInitializer.initialize();
    unawaited(sl<DevicePresenceService>().record().catchError((Object _) {}));
    unawaited(sl<ExpiryService>().start().catchError((Object _) {}));
    sl<AuthBloc>().add(const AuthStarted());
  }
}

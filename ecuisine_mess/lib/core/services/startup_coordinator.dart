import 'dart:async';

import 'package:ecuisine_mess/core/di/injection.dart';
import 'package:ecuisine_mess/core/services/local_mess_services.dart';
import 'package:ecuisine_mess/features/auth/presentation/bloc/auth_bloc.dart';

/// Coordinates optional post-frame startup work without blocking the first
/// Flutter frame.
class StartupCoordinator {
  StartupCoordinator._();

  static Future<void> start() async {
    // Auth restoration is deliberately dispatched after the UI has rendered.
    sl<AuthBloc>().add(const AuthStarted());

    // Keep local-service verification independent from the auth event. The
    // installed service manager normally starts both services at boot; this
    // check only provides recovery when the API is unexpectedly unavailable.
    if (LocalMessServices.canOfferLocalStart) {
      unawaited(_verifyLocalServer());
    }
  }

  static Future<void> _verifyLocalServer() async {
    if (await LocalMessServices.healthOk()) return;

    // Do not show a dialog or block startup here. MessServerGuard remains
    // responsible for user-facing recovery when runtime connectivity is lost.
  }
}

import 'package:ecuisine_mess/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase without making it a prerequisite for rendering the
/// desktop application shell.
class FirebaseInitializer {
  FirebaseInitializer._();

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized.');
    } catch (e, stack) {
      // Cloud-backed features handle their own failures. Firebase must not
      // prevent the local application from starting.
      debugPrint('Firebase initialization warning: $e\n$stack');
    }
  }
}

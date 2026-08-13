import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initializes Firebase without requiring platform config files to exist.
///
/// Option A decision (Task 7): the app keeps running even when Firebase
/// isn't configured. Now that the WEB app is registered in the project
/// (Firebase CLI), `initializeApp` receives the web options and succeeds;
/// native platforms still fall back to `google-services.json` /
/// `GoogleService-Info.plist` when those are added. Screens that need
/// Firebase check [isReady].
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _ready = false;

  /// True once [Firebase.initializeApp] succeeded on this run.
  static bool get isReady => _ready;

  static Future<void> init() async {
    try {
      // Web REQUIRES explicit options; native reads its platform config.
      await Firebase.initializeApp(
        options: kIsWeb ? DefaultFirebaseOptions.web : null,
      );
      _ready = true;
      debugPrint('Firebase initialized.');
    } catch (error) {
      // Expected when platform config is absent — not an app failure.
      debugPrint('Firebase not initialized (no platform config?): $error');
    }
  }
}

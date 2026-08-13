import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Firebase configuration per platform.
///
/// Generated shape mirrors what `flutterfire configure` produces. Only the
/// WEB app is registered in the project so far (created via the Firebase
/// CLI). Android/iOS use `google-services.json` / `GoogleService-Info.plist`
/// + `Firebase.initializeApp()` WITHOUT options, so they need no entry here
/// until those config files land.
///
/// Note: the web `apiKey` is NOT a secret — web SDK keys ship in every
/// client; authorization is enforced by Firebase Auth + Security Rules.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC7aOZuqIwqE3tCBeV9k7kz-nHyqS_HdgM',
    appId: '1:936582001674:web:3941db61545caed6e45bf3',
    messagingSenderId: '936582001674',
    projectId: 'doctor-appointment-booki-fc9d6',
    authDomain: 'doctor-appointment-booki-fc9d6.firebaseapp.com',
    storageBucket: 'doctor-appointment-booki-fc9d6.firebasestorage.app',
    measurementId: 'G-XXMYQGSY70',
  );
}

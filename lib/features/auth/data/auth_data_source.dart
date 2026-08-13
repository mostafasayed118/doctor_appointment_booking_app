import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../domain/auth_user.dart';

/// The only place in the auth feature that touches the Firebase SDK.
///
/// Converts Firebase's `User` into our domain [AuthUser] so nothing above
/// this file ever imports firebase_auth. The repository catches and maps
/// the SDK's exceptions; this file just talks to Firebase.
class AuthDataSource {
  AuthDataSource({auth.FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? auth.FirebaseAuth.instance;

  final auth.FirebaseAuth _auth;

  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toUser(credential.user!);
  }

  Future<AuthUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    if (displayName != null && displayName.trim().isNotEmpty) {
      await user.updateDisplayName(displayName.trim());
    }
    return _toUser(user);
  }

  Future<void> signOut() => _auth.signOut();

  /// Fires on every auth-state change (sign-in, sign-out, token refresh).
  Stream<AuthUser?> observeAuthState() =>
      _auth.authStateChanges().map((user) => user == null ? null : _toUser(user));

  AuthUser _toUser(auth.User user) => AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import '../../core/error/app_error.dart';

/// Maps Firebase exceptions to typed [AppError]s.
///
/// This is the single place where Firebase error types cross into the rest
/// of the app. It lives in the data layer (not core) because it depends on
/// the Firebase SDK — core stays pure Dart.
///
/// Repositories call [map] inside their catch blocks and return a
/// [Result] carrying the mapped error, so Cubits and widgets never see
/// Firebase exceptions directly.
class FirebaseErrorMapper {
  const FirebaseErrorMapper();

  /// Maps any thrown object to an [AppError].
  ///
  /// Handles the Firebase types we expect, and falls back to
  /// [UnexpectedError] for anything else — the error is never swallowed,
  /// just normalized to our typed contract.
  AppError map(Object error) {
    if (error is auth.FirebaseAuthException) {
      return _mapAuthException(error);
    }
    if (error is FirebaseException) {
      return _mapFirestoreException(error);
    }
    return UnexpectedError(message: error.toString());
  }

  AppError _mapAuthException(auth.FirebaseAuthException error) {
    // FirebaseAuthException.code is a stable machine-readable string like
    // 'invalid-credential', 'email-already-in-use', 'weak-password'.
    return AuthError(message: error.message ?? error.code);
  }

  AppError _mapFirestoreException(FirebaseException error) {
    // Firestore error codes: 'unavailable' (network), 'not-found',
    // 'permission-denied', 'aborted', etc.
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' || 'network-request-failed' =>
        NetworkError(message: error.message),
      'not-found' => NotFoundError(message: error.message),
      'permission-denied' => ServerError(
          message: error.message ?? 'You do not have permission to do that.',
        ),
      _ => ServerError(message: error.message),
    };
  }
}
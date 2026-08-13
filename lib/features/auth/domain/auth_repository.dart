import '../../../core/error/result.dart';
import 'auth_user.dart';

/// Contract the auth feature depends on.
///
/// The domain defines WHAT auth can do; the data layer decides HOW (Firebase
/// today, anything else tomorrow). Cubits depend on this interface, never on
/// a concrete implementation — that's what makes the cubit unit-testable
/// with mocktail and keeps Firebase out of presentation.
abstract interface class AuthRepository {
  /// Signs in with email/password.
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  });

  /// Creates a new account with email/password and signs in.
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs the current user out. Success is reported via the auth state
  /// stream (emits null) rather than a returned value.
  Future<Result<void>> signOut();

  /// Stream of the current user; emits null when signed out.
  ///
  /// This is the single source of truth for "who am I" — emitted
  /// automatically by Firebase on sign-in/out, token refresh, etc.
  Stream<AuthUser?> observeAuthState();
}

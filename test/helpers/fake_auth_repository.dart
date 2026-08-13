import 'dart:async';

import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_repository.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';

/// In-memory [AuthRepository] for widget tests.
///
/// Unlike a mocktail mock, this can be handed to the real [AuthCubit] and
/// the real [SignIn]/[SignUp]/[SignOut] use cases, so router and app-level
/// widget tests exercise the real auth state machine end-to-end without
/// Firebase.
///
/// The auth state stream is a sync broadcast controller: events added with
/// [emitAuthState] reach the cubit synchronously, mirroring Firebase's
/// stream-driven identity changes (sign-in/out, token refresh).
class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast(sync: true);

  /// Last user reported to the stream (what the cubit believes).
  AuthUser? currentUser;

  /// Failure overrides; when null the corresponding action succeeds.
  Result<AuthUser> Function()? failSignIn;
  Result<AuthUser> Function()? failSignUp;
  Result<void> Function()? failSignOut;

  @override
  Stream<AuthUser?> observeAuthState() => _controller.stream;

  /// Simulates Firebase emitting a new auth state (e.g. a stream-driven
  /// sign-out or an externally triggered session change).
  void emitAuthState(AuthUser? user) {
    currentUser = user;
    _controller.add(user);
  }

  @override
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    final fail = failSignIn;
    if (fail != null) return fail();
    return Success(currentUser ?? AuthUser(uid: 'u1', email: email));
  }

  @override
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final fail = failSignUp;
    if (fail != null) return fail();
    return Success(
      currentUser ?? AuthUser(uid: 'u1', email: email, displayName: displayName),
    );
  }

  @override
  Future<Result<void>> signOut() async {
    final fail = failSignOut;
    if (fail != null) return fail();
    return const Success<void>(null);
  }

  Future<void> dispose() => _controller.close();
}

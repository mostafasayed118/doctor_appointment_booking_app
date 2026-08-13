import 'package:equatable/equatable.dart';

import '../../../core/error/app_error.dart';
import '../domain/auth_user.dart';

/// All the states the auth UI can be in.
///
/// Sealed so the compiler knows every variant — exhaustive `switch`
/// matching is enforced, and no new state can be invented outside this file.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet (before the auth state stream's first event).
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// A sign-in/sign-up/sign-out request is in flight.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A user is signed in.
final class Authenticated extends AuthState {
  const Authenticated(this.user);

  final AuthUser user;

  @override
  List<Object?> get props => [user];
}

/// No user is signed in.
final class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// The last auth action (or the auth state stream) failed.
final class AuthError extends AuthState {
  const AuthError(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];
}

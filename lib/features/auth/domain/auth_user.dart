import 'package:equatable/equatable.dart';

/// An authenticated user, as seen by the rest of the app.
///
/// Feature-owned (not in `core/entities`) because only the auth feature
/// produces/consumes it; shared models like [Appointment] belong in core.
/// Pure Dart — the Firebase `User` type never crosses the domain boundary.
class AuthUser extends Equatable {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  final String uid;
  final String email;
  final String? displayName;

  @override
  List<Object?> get props => [uid, email, displayName];
}

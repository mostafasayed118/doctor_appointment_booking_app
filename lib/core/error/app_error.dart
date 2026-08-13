import 'package:equatable/equatable.dart';

/// A typed, user-presentable error produced at the repository boundary.
///
/// Cubits and widgets never see raw Firebase exceptions — repositories catch
/// them, map them here, and return a [Result] carrying one of these.
///
/// [AppError] is sealed: the two rules that matter are (1) the compiler knows
/// every possible subtype, so exhaustive pattern matching is enforced, and
/// (2) no new error type can be introduced outside this library.
sealed class AppError extends Equatable {
  const AppError({required this.code, required this.message});

  /// Stable machine-readable identifier, e.g. `auth_invalid_credentials`.
  final String code;

  /// Human-readable message. The presentation layer may prefer to map
  /// [code] to a localized string instead of showing [message] directly.
  final String message;

  @override
  List<Object?> get props => [code, message];
}

/// Network/connectivity failure — no connection, timeout, or transient
/// backend unavailability. The UI should offer a retry.
final class NetworkError extends AppError {
  const NetworkError({String? message})
      : super(
          code: 'network_error',
          message: message ?? 'Network connection failed. Please try again.',
        );
}

/// The backend rejected the request for a reason other than auth or a
/// missing document (e.g. permission rules, malformed data, quota).
final class ServerError extends AppError {
  const ServerError({String? message})
      : super(
          code: 'server_error',
          message: message ?? 'Something went wrong on our side. Please try again.',
        );
}

/// Authentication failure: wrong credentials, email in use, weak password,
/// disabled account, etc.
final class AuthError extends AppError {
  const AuthError({String? message})
      : super(
          code: 'auth_error',
          message: message ?? 'Authentication failed. Please check your details.',
        );
}

/// The requested slot can no longer be booked — it was taken by another
/// patient, or the appointment it belonged to changed state.
///
/// This is our own business rule, not a Firebase signal: the booking
/// repository throws this deliberately when a transaction can't verify the
/// slot, and the UI reacts with "slot no longer available — refresh".
final class SlotUnavailableError extends AppError {
  const SlotUnavailableError({String? message})
      : super(
          code: 'slot_unavailable',
          message: message ?? 'This time slot is no longer available.',
        );
}

/// A requested document (doctor, slot, appointment) does not exist.
final class NotFoundError extends AppError {
  const NotFoundError({String? message})
      : super(
          code: 'not_found',
          message: message ?? 'The requested item was not found.',
        );
}

/// Catch-all for anything that doesn't fit the types above. The error is
/// never swallowed — mapping it to [UnexpectedError] keeps the contract
/// "explicit failure" while still surfacing the real message.
final class UnexpectedError extends AppError {
  const UnexpectedError({required super.message})
      : super(code: 'unexpected_error');
}

import '../../features/auth/presentation/auth_state.dart';

/// Pure redirect decision for the auth guard.
///
/// Returns the location to redirect to, or null to stay put. Free of
/// GoRouter by design, so the redirect logic can be exhaustively
/// unit-tested without instantiating a router.
///
/// Rules:
/// - Signed out: every screen is protected EXCEPT the auth screens.
/// - Signed in: never camp on an auth screen — resume the pending deep link
///   or fall back to [/doctors] (the app's real landing); the root
///   resolves to [/doctors] too.
/// - Loading/error: never redirect mid-action or away from an error the
///   auth page needs to display.
String? authRedirect(
  AuthState state,
  String location, {
  String? pendingLocation,
}) {
  final isAuthRoute = location == '/login' || location == '/signup';
  return switch (state) {
    Authenticated() when isAuthRoute => pendingLocation ?? '/doctors',
    Authenticated() when location == '/' => '/doctors',
    Authenticated() => null,
    Unauthenticated() || AuthInitial() when !isAuthRoute => '/login',
    Unauthenticated() || AuthInitial() => null,
    AuthLoading() || AuthError() => null,
  };
}

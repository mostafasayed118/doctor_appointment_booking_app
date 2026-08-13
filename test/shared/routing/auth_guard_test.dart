import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/error/app_error.dart' as core;
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';
import 'package:doctor_appointment_booking_app/features/auth/presentation/auth_state.dart';
import 'package:doctor_appointment_booking_app/shared/routing/auth_guard.dart';

/// Pure-function tests for the redirect decision — no GoRouter needed.
///
/// Each rule from the guard's contract:
/// - Signed out: every screen is protected EXCEPT the auth screens.
/// - Signed in: never camp on an auth screen — resume the pending deep link
///   or fall back to [/home]; the root resolves to [/home] too.
/// - Loading/error: never redirect mid-action or away from an error the
///   auth page needs to display.
void main() {
  const user = AuthUser(uid: 'u1', email: 'ana@example.com');

  group('signed out (Unauthenticated)', () {
    test('every non-auth screen redirects to /login', () {
      expect(authRedirect(const Unauthenticated(), '/'), '/login');
      expect(authRedirect(const Unauthenticated(), '/home'), '/login');
      expect(authRedirect(const Unauthenticated(), '/doctors/abc'), '/login');
    });

    test('auth screens are allowed', () {
      expect(authRedirect(const Unauthenticated(), '/login'), isNull);
      expect(authRedirect(const Unauthenticated(), '/signup'), isNull);
    });
  });

  group('initial state (AuthInitial)', () {
    test('behaves like signed out', () {
      expect(authRedirect(const AuthInitial(), '/home'), '/login');
      expect(authRedirect(const AuthInitial(), '/login'), isNull);
    });
  });

  group('signed in (Authenticated)', () {
    test('auth screens redirect away — to the pending deep link if set', () {
      expect(authRedirect(Authenticated(user), '/login'), '/home');
      expect(
        authRedirect(Authenticated(user), '/login', pendingLocation: '/doctors/abc'),
        '/doctors/abc',
      );
      expect(
        authRedirect(Authenticated(user), '/signup', pendingLocation: '/appointments'),
        '/appointments',
      );
    });

    test('the root resolves to /home', () {
      expect(authRedirect(Authenticated(user), '/'), '/home');
    });

    test('protected screens are allowed once signed in', () {
      expect(authRedirect(Authenticated(user), '/home'), isNull);
      expect(authRedirect(Authenticated(user), '/doctors/abc'), isNull);
    });
  });

  group('transient states never redirect', () {
    test('AuthLoading stays put on any screen', () {
      expect(authRedirect(const AuthLoading(), '/'), isNull);
      expect(authRedirect(const AuthLoading(), '/home'), isNull);
      expect(authRedirect(const AuthLoading(), '/login'), isNull);
    });

    test('AuthError stays put so the auth page can display it', () {
      expect(authRedirect(const AuthError(core.NetworkError()), '/home'), isNull);
      expect(authRedirect(const AuthError(core.NetworkError()), '/login'), isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';
import 'package:doctor_appointment_booking_app/di/locator.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_app.dart';

/// GoRouter wiring tests over the real [AuthCubit] + redirect closure.
///
/// The pure redirect rules are exhaustively tested in auth_guard_test.dart;
/// these prove the wiring: the guard is attached, the cubit re-triggers it
/// on every state change, and the pending deep link is stored and restored.
///
/// Bounded pumps only — the gallery home contains infinite LoadingView
/// spinners, so pumpAndSettle would time out. Auth-driven navigation needs
/// a few frames for the stream delivery + page transition to complete.
void main() {
  const user = AuthUser(uid: 'u1', email: 'ana@example.com');

  setUp(setupLocator);
  tearDown(resetLocator);

  /// Pumps through a GoRouter page transition without settling on the
  /// gallery's forever-animating spinners.
  Future<void> settleTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a signed-out user is bounced to /login', (tester) async {
    final harness = buildTestApp(repository: FakeAuthRepository());

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);

    // AppBar title and submit button both read "Sign in".
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Shared components'), findsNothing);
  });

  testWidgets('an authenticated user starts at /home', (tester) async {
    final harness = buildTestApp(repository: FakeAuthRepository(), initialUser: user);

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);

    expect(find.text('Shared components'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('signing in from /login lands on /home (fallback)', (tester) async {
    final harness = buildTestApp(repository: FakeAuthRepository());

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);
    expect(find.text('Sign in'), findsWidgets);

    await harness.cubit.signIn(email: 'ana@example.com', password: 'secret123');
    await settleTransition(tester);

    expect(find.text('Shared components'), findsOneWidget);
  });

  testWidgets('a deep link to /home is restored after sign-in', (tester) async {
    // Start pointed at a protected location: the guard bounces to /login
    // and remembers where the user wanted to go.
    final harness = buildTestApp(
      repository: FakeAuthRepository(),
      initialLocation: '/home',
    );

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);
    expect(find.text('Sign in'), findsWidgets);

    await harness.cubit.signIn(email: 'ana@example.com', password: 'secret123');
    await settleTransition(tester);

    // Restored to the requested location, not a hardcoded landing page.
    expect(find.text('Shared components'), findsOneWidget);
  });

  testWidgets('signing out returns to /login via the stream', (tester) async {
    final harness = buildTestApp(repository: FakeAuthRepository(), initialUser: user);

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);
    expect(find.text('Shared components'), findsOneWidget);

    // Tap the gallery AppBar sign-out action (dev convenience).
    await tester.tap(find.text('Sign out'));
    await tester.pump();

    // Firebase reports the session ended via the auth state stream — the
    // cubit waits for it (single source of truth for identity).
    harness.repository.emitAuthState(null);
    await settleTransition(tester);

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Shared components'), findsNothing);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';
import 'package:doctor_appointment_booking_app/di/locator.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_app.dart';

/// GoRouter wiring tests over the real [AuthCubit] + redirect closure.
///
/// The pure redirect rules are exhaustively tested in auth_guard_test.dart;
/// these prove the wiring: the guard is attached, the cubit re-triggers it
/// on every state change, and the pending deep link is stored and restored.
/// The post-auth landing is /doctors (the real feature), not the dev
/// gallery — so navigation to it runs the real doctors cubit chain over the
/// harness's fake repository.
///
/// Bounded pumps only — the pages contain infinite LoadingView spinners, so
/// pumpAndSettle would time out.
void main() {
  const user = AuthUser(uid: 'u1', email: 'ana@example.com');
  const ana = Doctor(
    id: 'd1',
    name: 'Ana Patel',
    specialty: 'Cardiology',
    bio: 'Cardiologist with 15 years of experience.',
    rating: 4.8,
    clinicAddress: '12 Medical Ave',
    photoUrl: '',
  );

  setUp(setupLocator);
  tearDown(resetLocator);

  /// Pumps through a GoRouter page transition without settling on
  /// forever-animating spinners. Generous: leaving /doctors (with its
  /// cubit teardown) takes ~1.2s of pumped time, so three 500ms pumps
  /// after the trigger keep every assertion past the transition.
  Future<void> settleTransition(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets('a signed-out user is bounced to /login', (tester) async {
    final harness = buildTestApp(repository: FakeAuthRepository());

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);

    // AppBar title and submit button both read "Sign in".
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Doctors'), findsNothing);
  });

  testWidgets('an authenticated user lands on /doctors', (tester) async {
    final harness = buildTestApp(
      repository: FakeAuthRepository(),
      initialUser: user,
    );

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);

    expect(find.text('Doctors'), findsOneWidget);
    expect(find.text('No doctors yet'), findsOneWidget);
  });

  testWidgets('signing in from /login lands on /doctors', (tester) async {
    final harness = buildTestApp(repository: FakeAuthRepository());

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);
    expect(find.text('Sign in'), findsWidgets);

    await harness.cubit.signIn(email: 'ana@example.com', password: 'secret123');
    await settleTransition(tester);

    expect(find.text('Doctors'), findsOneWidget);
  });

  testWidgets('a deep link to /doctors/d1 is restored after sign-in',
      (tester) async {
    // Start pointed at a protected profile deep link: the guard bounces to
    // /login and remembers where the user wanted to go.
    final harness = buildTestApp(
      repository: FakeAuthRepository(),
      initialLocation: '/doctors/d1',
      doctors: const [ana],
    );

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);
    expect(find.text('Sign in'), findsWidgets);

    await harness.cubit.signIn(email: 'ana@example.com', password: 'secret123');
    await settleTransition(tester);

    // Restored to the EXACT deep link — the profile page, not the list.
    expect(find.text('Doctor profile'), findsOneWidget);
    expect(find.text('Ana Patel'), findsOneWidget);
  });

  testWidgets('signing out returns to /login via the stream', (tester) async {
    final harness = buildTestApp(
      repository: FakeAuthRepository(),
      initialUser: user,
    );

    await tester.pumpWidget(harness.app);
    await settleTransition(tester);
    expect(find.text('Doctors'), findsOneWidget);

    // Sign-out success is reported by the auth state stream — the cubit
    // waits for it (single source of truth for identity).
    await harness.cubit.signOut();
    await tester.pump();
    harness.repository.emitAuthState(null);
    await settleTransition(tester);

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Doctors'), findsNothing);
  });
}

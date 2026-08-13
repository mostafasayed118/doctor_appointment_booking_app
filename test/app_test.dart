import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/app.dart';
import 'package:doctor_appointment_booking_app/di/locator.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';
import 'package:doctor_appointment_booking_app/shared/services/locale_service.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

void main() {
  const user = AuthUser(uid: 'u1', email: 'ana@example.com');

  // The app shell resolves LocaleService via GetIt during build; the router
  // is injected (over a fake-auth AuthCubit) so no Firebase is touched.
  setUp(() => setupLocator());
  tearDown(resetLocator);

  /// Directionality of the given widget's enclosing context — this is what
  /// actually governs how text/layout flows (LTR vs RTL).
  TextDirection directionOf(WidgetTester tester, Finder finder) =>
      Directionality.of(tester.element(finder));

  /// The harness starts already authenticated (the guard would otherwise
  /// park the app on /login) so the localization assertions can reach the
  /// real landing — the doctors list, which is fully localized.
  DoctorAppointmentApp buildAuthenticatedApp() =>
      buildTestApp(repository: FakeAuthRepository(), initialUser: user).app;

  // Bounded pumps, not pumpAndSettle: the doctors page's LoadingView
  // spinner animates forever, so pumpAndSettle would time out.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('DoctorAppointmentApp localization', () {
    testWidgets('renders English (LTR) by default', (tester) async {
      await tester.pumpWidget(buildAuthenticatedApp());
      await settle(tester);

      // The signed-in landing is the doctors list (localized title + the
      // empty-state copy for the harness's empty fake data).
      expect(find.text('Doctors'), findsOneWidget);
      expect(find.text('No doctors yet'), findsOneWidget);

      expect(
        directionOf(tester, find.text('No doctors yet')),
        TextDirection.ltr,
      );
    });

    testWidgets('switches to RTL when the locale is set to ar',
        (tester) async {
      sl<LocaleService>().setLocale(const Locale('ar'));

      await tester.pumpWidget(buildAuthenticatedApp());
      await settle(tester);

      // The toggle advertises its target language, and the localized
      // doctors copy flipped to Arabic + RTL.
      expect(find.text('English'), findsOneWidget);
      expect(find.text('الأطباء'), findsOneWidget);
      expect(
        directionOf(tester, find.text('الأطباء')),
        TextDirection.rtl,
      );
    });

    testWidgets('tapping the language toggle switches the UI live',
        (tester) async {
      await tester.pumpWidget(buildAuthenticatedApp());
      await settle(tester);

      // In English the toggle advertises its target: "العربية".
      expect(find.text('العربية'), findsOneWidget);

      await tester.tap(find.text('العربية'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Toggle now advertises English, and the layout flipped to RTL.
      expect(find.text('English'), findsOneWidget);
      expect(
        directionOf(tester, find.text('الأطباء')),
        TextDirection.rtl,
      );
    });
  });
}

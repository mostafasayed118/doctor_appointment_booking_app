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
  /// gallery home where the theme + toggle live.
  DoctorAppointmentApp buildAuthenticatedApp() =>
      buildTestApp(repository: FakeAuthRepository(), initialUser: user).app;

  group('DoctorAppointmentApp localization', () {
    testWidgets('renders English (LTR) by default', (tester) async {
      await tester.pumpWidget(buildAuthenticatedApp());
      // Bounded pumps, not pumpAndSettle: the gallery's LoadingView
      // spinners animate forever, so pumpAndSettle would time out.
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Shared components'), findsOneWidget);

      expect(
        directionOf(tester, find.text('Shared components')),
        TextDirection.ltr,
      );
    });

    testWidgets('switches to RTL when the locale is set to ar',
        (tester) async {
      sl<LocaleService>().setLocale(const Locale('ar'));

      await tester.pumpWidget(buildAuthenticatedApp());
      await tester.pump(const Duration(milliseconds: 400));

      // The gallery's own strings are dev-only English, but the locale flows
      // into the widget tree — visible via the toggle label (localized) and
      // the flipped Directionality.
      expect(find.text('English'), findsOneWidget);
      expect(
        directionOf(tester, find.text('Shared components')),
        TextDirection.rtl,
      );
    });

    testWidgets('tapping the language toggle switches the UI live',
        (tester) async {
      await tester.pumpWidget(buildAuthenticatedApp());
      await tester.pump(const Duration(milliseconds: 400));

      // In English the toggle advertises its target: "العربية".
      expect(find.text('العربية'), findsOneWidget);

      await tester.tap(find.text('العربية'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Toggle now advertises English, and the layout flipped to RTL.
      expect(find.text('English'), findsOneWidget);
      expect(
        directionOf(tester, find.text('Shared components')),
        TextDirection.rtl,
      );
    });
  });
}

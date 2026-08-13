import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/app.dart';
import 'package:doctor_appointment_booking_app/di/locator.dart';
import 'package:doctor_appointment_booking_app/shared/services/locale_service.dart';

void main() {
  setUp(setupLocator);
  tearDown(resetLocator);

  /// Directionality of the given widget's enclosing context — this is what
  /// actually governs how text/layout flows (LTR vs RTL).
  TextDirection directionOf(WidgetTester tester, Finder finder) =>
      Directionality.of(tester.element(finder));

  group('DoctorAppointmentApp localization', () {
    testWidgets('renders English (LTR) by default', (tester) async {
      await tester.pumpWidget(const DoctorAppointmentApp());

      expect(find.text('Shared components'), findsOneWidget);

      expect(
        directionOf(tester, find.text('Shared components')),
        TextDirection.ltr,
      );
    });

    testWidgets('switches to RTL when the locale is set to ar',
        (tester) async {
      sl<LocaleService>().setLocale(const Locale('ar'));

      await tester.pumpWidget(const DoctorAppointmentApp());

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
      await tester.pumpWidget(const DoctorAppointmentApp());

      // In English the toggle advertises its target: "العربية".
      expect(find.text('العربية'), findsOneWidget);

      await tester.tap(find.text('العربية'));
      // Bounded pumps, not pumpAndSettle: the gallery's LoadingView
      // spinners animate forever, so pumpAndSettle would time out.
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

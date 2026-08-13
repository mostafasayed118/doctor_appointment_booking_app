import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/app.dart';
import 'package:doctor_appointment_booking_app/di/locator.dart';

void main() {
  // The app shell resolves LocaleService via GetIt during build, so the
  // locator must be wired before pumping (mirrors lib/main.dart).
  setUp(setupLocator);
  tearDown(resetLocator);

  testWidgets('App builds and shows the dev home (component gallery)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DoctorAppointmentApp());

    expect(find.text('Shared components'), findsOneWidget);
    // First section is in the initial viewport; ListView builds lazily,
    // so below-the-fold sections are not part of the tree yet.
    expect(find.text('Theme'), findsOneWidget);
  });
}

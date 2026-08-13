import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/di/locator.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/test_app.dart';

void main() {
  // The app shell resolves LocaleService via GetIt during build, so the
  // locator must be wired before pumping (mirrors lib/main.dart).
  setUp(setupLocator);
  tearDown(resetLocator);

  testWidgets('App builds; signed-out users are parked on /login by the guard',
      (WidgetTester tester) async {
    final harness = buildTestApp(repository: FakeAuthRepository());

    await tester.pumpWidget(harness.app);
    await tester.pump(const Duration(milliseconds: 400));

    // The auth guard owns entry now: no gallery, login form instead.
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Shared components'), findsNothing);
  });
}

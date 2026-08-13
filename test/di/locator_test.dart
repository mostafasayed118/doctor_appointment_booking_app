import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/di/locator.dart';

void main() {
  tearDown(resetLocator);

  test('setupLocator registers the placeholder service', () {
    setupLocator();

    expect(sl.isRegistered<PlaceholderService>(), isTrue);
  });

  test('resolving the placeholder service returns an instance', () {
    setupLocator();

    final service = sl<PlaceholderService>();

    expect(service, isA<PlaceholderService>());
  });

  test('resetLocator clears all registrations', () async {
    setupLocator();
    expect(sl.isRegistered<PlaceholderService>(), isTrue);

    await resetLocator();

    expect(sl.isRegistered<PlaceholderService>(), isFalse);
  });
}
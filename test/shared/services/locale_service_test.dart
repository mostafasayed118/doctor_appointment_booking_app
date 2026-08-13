import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/shared/services/locale_service.dart';

void main() {
  group('LocaleService', () {
    test('defaults to English', () {
      final service = LocaleService();

      expect(service.locale, const Locale('en'));
    });

    test('setLocale updates the locale and notifies', () {
      final service = LocaleService();
      var notifications = 0;
      service.addListener(() => notifications++);

      service.setLocale(const Locale('ar'));

      expect(service.locale, const Locale('ar'));
      expect(notifications, 1);
    });

    test('setLocale rejects unsupported locales', () {
      final service = LocaleService();

      service.setLocale(const Locale('fr'));

      expect(service.locale, const Locale('en'));
    });

    test('setLocale with the current locale does not notify', () {
      final service = LocaleService();
      var notifications = 0;
      service.addListener(() => notifications++);

      service.setLocale(const Locale('en'));

      expect(notifications, 0);
    });

    test('toggle switches en -> ar -> en', () {
      final service = LocaleService();

      service.toggle();
      expect(service.locale, const Locale('ar'));

      service.toggle();
      expect(service.locale, const Locale('en'));
    });

    test('supports an initial locale other than the default', () {
      final service = LocaleService(initialLocale: const Locale('ar'));

      expect(service.locale, const Locale('ar'));
    });
  });
}

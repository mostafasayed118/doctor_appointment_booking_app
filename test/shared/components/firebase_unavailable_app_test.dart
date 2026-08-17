import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/di/locator.dart';
import 'package:doctor_appointment_booking_app/shared/components/firebase_unavailable_app.dart';
import 'package:doctor_appointment_booking_app/shared/services/locale_service.dart';

/// The degraded screen shown when Firebase can't initialize: it must render
/// a clear explanation (in EN and AR) without constructing any Firebase
/// dependency — that's the whole point of the guard. If it ever touches
/// Firebase, resolving it in a test would throw [core/no-app] here.
void main() {
  setUp(setupLocator);
  tearDown(resetLocator);

  testWidgets('renders the explanation in English', (tester) async {
    await tester.pumpWidget(const FirebaseUnavailableApp());
    await tester.pump();

    expect(find.text('Firebase is not configured'), findsOneWidget);
    expect(find.textContaining('google-services.json'), findsOneWidget);
  });

  testWidgets('renders the explanation in Arabic', (tester) async {
    final localeService = sl<LocaleService>();
    localeService.setLocale(const Locale('ar'));
    await tester.pumpWidget(const FirebaseUnavailableApp());
    await tester.pump();

    expect(find.text('Firebase غير مُهيّأ'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/error/app_error.dart';
import 'package:doctor_appointment_booking_app/l10n/app_localizations.dart';
import 'package:doctor_appointment_booking_app/shared/components/app_error_view.dart';

void main() {
  // The retry label comes from AppLocalizations, so the test wrapper needs
  // the localization delegates (defaults to English).
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  const error = NetworkError(message: 'No connection.');

  group('AppErrorView', () {
    testWidgets('renders the error message', (tester) async {
      await tester.pumpWidget(
        wrap(const AppErrorView(error: error)),
      );

      expect(find.text('No connection.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('fires onRetry when the retry button is tapped',
        (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        wrap(AppErrorView(error: error, onRetry: () => retries++)),
      );

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    testWidgets('hides the retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        wrap(const AppErrorView(error: error)),
      );

      expect(find.text('Retry'), findsNothing);
    });
  });
}

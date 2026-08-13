import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/shared/components/app_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AppButton', () {
    testWidgets('renders the label and optional icon', (tester) async {
      await tester.pumpWidget(
        wrap(const AppButton(
          label: 'Book appointment',
          onPressed: null,
          icon: Icons.calendar_today,
        )),
      );

      expect(find.text('Book appointment'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('fires onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(AppButton(
          label: 'Retry',
          onPressed: () => taps++,
        )),
      );

      await tester.tap(find.text('Retry'));
      expect(taps, 1);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        wrap(const AppButton(label: 'Submit', onPressed: null)),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('loading shows a spinner and blocks taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(AppButton(
          label: 'Book',
          loading: true,
          onPressed: () => taps++,
        )),
      );

      // Label is replaced by the spinner.
      expect(find.text('Book'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Spinner is visible against the filled background (onPrimary).
      final spinner =
          tester.widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator));
      expect(spinner.color, isNotNull);
      expect(spinner.strokeWidth, 2);

      // Loading forces the button disabled, so taps do nothing.
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      expect(taps, 0);
    });
  });
}

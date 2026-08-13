import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/shared/components/loading_view.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('LoadingView', () {
    testWidgets('renders a spinner with an optional label', (tester) async {
      await tester.pumpWidget(
        wrap(const LoadingView(label: 'Loading doctors…')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading doctors…'), findsOneWidget);
    });

    testWidgets('renders the spinner alone when label is null', (tester) async {
      await tester.pumpWidget(wrap(const LoadingView()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });
  });
}

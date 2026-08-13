import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/shared/components/empty_state.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('EmptyState', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        wrap(const EmptyState(
          icon: Icons.event_busy,
          title: 'No appointments',
          subtitle: 'Book one to get started.',
        )),
      );

      expect(find.byIcon(Icons.event_busy), findsOneWidget);
      expect(find.text('No appointments'), findsOneWidget);
      expect(find.text('Book one to get started.'), findsOneWidget);
    });

    testWidgets('omits the subtitle when null', (tester) async {
      await tester.pumpWidget(
        wrap(const EmptyState(icon: Icons.search_off, title: 'No results')),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No results'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget); // title only, no subtitle
    });
  });
}

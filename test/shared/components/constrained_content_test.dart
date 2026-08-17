import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/shared/components/constrained_content.dart';

void main() {
  group('ConstrainedContent', () {
    testWidgets('renders the child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ConstrainedContent(child: Text('hello'))),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('caps the content width to maxWidth', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstrainedContent(maxWidth: 400, child: Text('x')),
          ),
        ),
      );

      // The ConstrainedBox inside ConstrainedContent carries the cap.
      final box = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ConstrainedContent),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.maxWidth, 400);
    });

    testWidgets('centers the child when the screen is wider than maxWidth', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConstrainedContent(
              maxWidth: 400,
              child: SizedBox(width: 100, height: 100, child: Text('x')),
            ),
          ),
        ),
      );

      // (1200 - 100) / 2 — centered on the wide screen, not edge-to-edge.
      final rect = tester.getRect(find.byType(SizedBox));
      expect(rect.left, closeTo(550, 0.1));
      expect(rect.width, 100);
    });
  });
}

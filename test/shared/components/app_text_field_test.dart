import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/shared/components/app_text_field.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('AppTextField', () {
    testWidgets('renders label, hint, and error text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(AppTextField(
          controller: controller,
          label: 'Email',
          hint: 'you@example.com',
          errorText: 'Required',
        )),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('you@example.com'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('typing updates the controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(AppTextField(controller: controller, label: 'Name')),
      );

      await tester.enterText(find.byType(TextField), 'Dr. Smith');
      expect(controller.text, 'Dr. Smith');
    });

    testWidgets('obscures input when obscureText is set', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(AppTextField(
          controller: controller,
          label: 'Password',
          obscureText: true,
        )),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.obscureText, isTrue);
    });

    testWidgets('submits via onSubmitted', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      String? submitted;
      await tester.pumpWidget(
        wrap(AppTextField(
          controller: controller,
          label: 'Search',
          onSubmitted: (value) => submitted = value,
        )),
      );

      await tester.enterText(find.byType(TextField), 'Cardiology');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submitted, 'Cardiology');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/main.dart';

void main() {
  testWidgets('App builds and shows the placeholder home page',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DoctorAppointmentApp());

    expect(find.text('Doctor Appointment Booking'), findsOneWidget);
    expect(find.text('Project scaffold ready.'), findsOneWidget);
  });
}
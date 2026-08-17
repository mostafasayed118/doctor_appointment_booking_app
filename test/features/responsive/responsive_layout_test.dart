import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/core/entities/time_slot.dart';
import 'package:doctor_appointment_booking_app/di/locator.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';
import 'package:doctor_appointment_booking_app/features/booking/presentation/widgets/slot_tile.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/widgets/doctor_card.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/test_app.dart';

/// Responsive layout smoke tests: every key screen is pumped through the
/// REAL router/cubit chain (over the harness fakes) at phone and tablet
/// sizes. RenderFlex overflows throw [FlutterError] in widget tests, so
/// "renders without exceptions" is exactly the regression Task 16 fixes.
///
/// Bounded pumps only — the pages contain infinite LoadingView spinners, so
/// pumpAndSettle would time out.
void main() {
  const user = AuthUser(uid: 'u1', email: 'ana@example.com');
  const ana = Doctor(
    id: 'd1',
    name: 'Ana Patel',
    specialty: 'Cardiology',
    bio: 'Cardiologist with 15 years of experience.',
    rating: 4.8,
    clinicAddress: '12 Medical Ave',
    photoUrl: '',
  );

  // Slots/appointments must be in the FUTURE relative to the real clock —
  // the slot selection and appointments cubits split on DateTime.now().
  TimeSlot futureSlot(String id) {
    final start = DateTime.now().add(const Duration(days: 3));
    return TimeSlot(
      id: id,
      doctorId: 'd1',
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
      isBooked: false,
    );
  }

  Appointment futureAppointment() {
    final start = DateTime.now().add(const Duration(days: 4));
    return Appointment(
      id: 'appt-1',
      patientId: user.uid,
      doctorId: 'd1',
      slotId: 's-appt',
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
      status: AppointmentStatus.scheduled,
      createdAt: DateTime.now(),
    );
  }

  setUp(setupLocator);
  tearDown(resetLocator);

  /// Pumps [location] through the real router at [size] with bounded pumps.
  Future<void> pumpRoute(
    WidgetTester tester,
    Size size, {
    required String location,
    required bool signedIn,
    List<Doctor> doctors = const [],
    Map<String, List<TimeSlot>> slotsByDoctor = const {},
    List<Appointment> appointments = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final harness = buildTestApp(
      repository: FakeAuthRepository(),
      initialUser: signedIn ? user : null,
      initialLocation: location,
      doctors: doctors,
      slotsByDoctor: slotsByDoctor,
      appointments: appointments,
    );
    await tester.pumpWidget(harness.app);
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> settleTransition(WidgetTester tester) async {
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  const sizes = [Size(400, 800), Size(900, 1400)];

  for (final size in sizes) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    group('at $label', () {
      testWidgets('login form renders without overflow', (tester) async {
        await pumpRoute(tester, size, location: '/login', signedIn: false);
        expect(find.text('Sign in'), findsWidgets);
      });

      testWidgets('doctors list renders without overflow', (tester) async {
        await pumpRoute(
          tester,
          size,
          location: '/doctors',
          signedIn: true,
          doctors: const [ana],
        );
        expect(find.text('Ana Patel'), findsOneWidget);
      });

      testWidgets('doctor profile renders without overflow', (tester) async {
        await pumpRoute(
          tester,
          size,
          location: '/doctors/d1',
          signedIn: true,
          doctors: const [ana],
        );
        expect(find.text('Doctor profile'), findsOneWidget);
        expect(find.text('Ana Patel'), findsOneWidget);
      });

      testWidgets('slot selection + confirm flow renders without overflow', (
        tester,
      ) async {
        await pumpRoute(
          tester,
          size,
          location: '/doctors/d1/book',
          signedIn: true,
          doctors: const [ana],
          slotsByDoctor: {
            'd1': [futureSlot('s1')],
          },
        );
        expect(find.byType(SlotTile), findsOneWidget);

        // Select the slot, then confirm — runs the real booking cubit chain
        // over the fake repository into the confirmation page.
        await tester.tap(find.byType(SlotTile));
        await tester.pump();
        await tester.tap(find.text('Confirm booking'));
        await settleTransition(tester);

        expect(find.text('Appointment booked!'), findsOneWidget);
      });

      testWidgets('appointments renders without overflow', (tester) async {
        await pumpRoute(
          tester,
          size,
          location: '/appointments',
          signedIn: true,
          doctors: const [ana],
          appointments: [futureAppointment()],
        );
        expect(find.text('My appointments'), findsOneWidget);
        expect(find.text('Ana Patel'), findsOneWidget);
      });

      testWidgets('reschedule confirm flow reaches the confirmation page', (
        tester,
      ) async {
        // Regression: Task 14's reschedule confirm push ended on the router's
        // 'Route not found' error page in production — the reschedule route's
        // redirect only accepts a bare Appointment extra, but the confirm push
        // carries a (Appointment, TimeSlot) record. Drive the REAL router
        // through the whole flow: appointments → reschedule → pick a slot →
        // confirm — and assert we land on the reschedule confirmation.
        await pumpRoute(
          tester,
          size,
          location: '/appointments',
          signedIn: true,
          doctors: const [ana],
          slotsByDoctor: {
            'd1': [futureSlot('s2')],
          },
          appointments: [futureAppointment()],
        );
        expect(find.text('My appointments'), findsOneWidget);

        await tester.tap(find.text('Reschedule'));
        await settleTransition(tester);
        expect(find.text('Reschedule appointment'), findsOneWidget);

        await tester.tap(find.byType(SlotTile));
        await tester.pump();
        await tester.tap(find.text('Reschedule'));
        await settleTransition(tester);

        expect(
          find.text('Route not found'),
          findsNothing,
          reason: 'the reschedule confirm push must resolve, not error',
        );
        expect(find.text('Appointment rescheduled!'), findsOneWidget);
      });
    });
  }

  testWidgets('doctors list content is capped on a desktop-width screen', (
    tester,
  ) async {
    await pumpRoute(
      tester,
      const Size(1400, 900),
      location: '/doctors',
      signedIn: true,
      doctors: const [ana],
    );

    // The card must be capped (~900 content) and centered, not stretched
    // edge-to-edge across the 1400-wide screen.
    final cardRect = tester.getRect(find.byType(DoctorCard));
    expect(cardRect.width, lessThan(1200));
    expect(cardRect.center.dx, closeTo(700, 1));
  });
}

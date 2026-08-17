import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/features/appointments/data/firestore_appointments_data_source.dart'
    show AppointmentAlreadyCancelledException;
import 'package:doctor_appointment_booking_app/features/booking/data/firestore_booking_data_source.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreBookingDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreBookingDataSource(firestore: firestore);
  });

  Future<void> seedSlot({
    required String id,
    required String doctorId,
    required DateTime start,
    bool isBooked = false,
  }) async {
    await firestore.collection('slots').doc(id).set({
      'doctorId': doctorId,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(start.add(const Duration(hours: 1))),
      'isBooked': isBooked,
    });
  }

  /// Seeds an appointment exactly as bookSlot writes it, plus the slot it
  /// references (reschedule frees it).
  Future<void> seedAppointment({
    required String id,
    required String patientId,
    required String doctorId,
    required String slotId,
    required DateTime start,
    String status = 'scheduled',
  }) async {
    await firestore.collection('appointments').doc(id).set({
      'patientId': patientId,
      'doctorId': doctorId,
      'slotId': slotId,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(start.add(const Duration(hours: 1))),
      'status': status,
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 8, 1, 12)),
    });
  }

  group('bookSlot', () {
    test(
      'creates the appointment and flips the slot in one atomic write',
      () async {
        final start = DateTime.utc(2026, 8, 20, 9);
        await seedSlot(id: 's1', doctorId: 'd1', start: start);

        final appointment = await dataSource.bookSlot(
          patientId: 'p1',
          slotId: 's1',
        );

        // The returned entity is built from what the transaction committed.
        expect(appointment.patientId, 'p1');
        expect(appointment.doctorId, 'd1');
        expect(appointment.slotId, 's1');
        expect(appointment.startTime, start); // UTC round-trip
        expect(appointment.endTime, start.add(const Duration(hours: 1)));
        expect(appointment.status, AppointmentStatus.scheduled);

        // Both writes landed together.
        final slotDoc = await firestore.collection('slots').doc('s1').get();
        expect(slotDoc.data()!['isBooked'], isTrue);

        final apptDocs = await firestore.collection('appointments').get();
        expect(apptDocs.docs, hasLength(1));
        expect(apptDocs.docs.single.data()['patientId'], 'p1');
        expect(apptDocs.docs.single.data()['slotId'], 's1');
        expect(apptDocs.docs.single.data()['status'], 'scheduled');
      },
    );

    test('aborts with SlotUnavailableException when the slot is already '
        'booked — the state a concurrent race converges to', () async {
      await seedSlot(
        id: 's1',
        doctorId: 'd1',
        start: DateTime.utc(2026, 8, 20, 9),
        isBooked: true,
      );

      await expectLater(
        dataSource.bookSlot(patientId: 'p1', slotId: 's1'),
        throwsA(isA<SlotUnavailableException>()),
      );

      // Nothing was half-written.
      final apptDocs = await firestore.collection('appointments').get();
      expect(apptDocs.docs, isEmpty);
    });

    test('aborts with a not-found FirebaseException when the slot document '
        'is missing', () async {
      await expectLater(
        dataSource.bookSlot(patientId: 'p1', slotId: 'no-such-slot'),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );

      final apptDocs = await firestore.collection('appointments').get();
      expect(apptDocs.docs, isEmpty);
    });

    test('aborts with SlotUnavailableException when the slot has already '
        'started', () async {
      final pastStart = DateTime.now().subtract(const Duration(hours: 2));
      await seedSlot(id: 's1', doctorId: 'd1', start: pastStart);

      await expectLater(
        dataSource.bookSlot(patientId: 'p1', slotId: 's1'),
        throwsA(isA<SlotUnavailableException>()),
      );
    });
  });

  group('rescheduleAppointment', () {
    final newStart = DateTime.utc(2026, 8, 21, 10);

    test('frees the old slot, books the new one, and re-points the '
        'appointment in one atomic write', () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's-old',
        start: DateTime.utc(2026, 8, 20, 9),
      );
      await seedSlot(id: 's-old', doctorId: 'd1', start: DateTime.utc(2026, 8, 20, 9), isBooked: true);
      await seedSlot(id: 's-new', doctorId: 'd1', start: newStart);

      final moved = await dataSource.rescheduleAppointment(
        patientId: 'p1',
        appointmentId: 'a1',
        newSlotId: 's-new',
      );

      // The returned entity reflects what the transaction committed.
      expect(moved.id, 'a1');
      expect(moved.slotId, 's-new');
      expect(moved.startTime, newStart); // UTC round-trip
      expect(moved.status, AppointmentStatus.scheduled);

      // All three writes landed together.
      final newSlotDoc = await firestore.collection('slots').doc('s-new').get();
      expect(newSlotDoc.data()!['isBooked'], isTrue);
      final oldSlotDoc = await firestore.collection('slots').doc('s-old').get();
      expect(oldSlotDoc.data()!['isBooked'], isFalse);
      final apptDoc = await firestore.collection('appointments').doc('a1').get();
      expect(apptDoc.data()!['slotId'], 's-new');
      expect(apptDoc.data()!['status'], 'scheduled');
    });

    test('aborts with SlotUnavailableException when the new slot is already '
        'booked — the state a concurrent race converges to', () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's-old',
        start: DateTime.utc(2026, 8, 20, 9),
      );
      await seedSlot(id: 's-old', doctorId: 'd1', start: DateTime.utc(2026, 8, 20, 9), isBooked: true);
      await seedSlot(id: 's-new', doctorId: 'd1', start: newStart, isBooked: true);

      await expectLater(
        dataSource.rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 's-new',
        ),
        throwsA(isA<SlotUnavailableException>()),
      );

      // Nothing was half-written.
      final oldSlotDoc = await firestore.collection('slots').doc('s-old').get();
      expect(oldSlotDoc.data()!['isBooked'], isTrue);
      final apptDoc = await firestore.collection('appointments').doc('a1').get();
      expect(apptDoc.data()!['slotId'], 's-old');
    });

    test('aborts with SlotUnavailableException when the new slot has already '
        'started', () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's-old',
        start: DateTime.utc(2026, 8, 20, 9),
      );
      await seedSlot(id: 's-old', doctorId: 'd1', start: DateTime.utc(2026, 8, 20, 9), isBooked: true);
      final pastStart = DateTime.now().subtract(const Duration(hours: 2));
      await seedSlot(id: 's-new', doctorId: 'd1', start: pastStart);

      await expectLater(
        dataSource.rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 's-new',
        ),
        throwsA(isA<SlotUnavailableException>()),
      );
    });

    test('aborts with a not-found FirebaseException when the new slot '
        'document is missing', () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's-old',
        start: DateTime.utc(2026, 8, 20, 9),
      );
      await seedSlot(id: 's-old', doctorId: 'd1', start: DateTime.utc(2026, 8, 20, 9), isBooked: true);

      await expectLater(
        dataSource.rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 'no-such-slot',
        ),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });

    test('aborts with a not-found FirebaseException when the appointment '
        'is missing', () async {
      await seedSlot(id: 's-new', doctorId: 'd1', start: newStart);

      await expectLater(
        dataSource.rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'no-such-appt',
          newSlotId: 's-new',
        ),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });

    test('treats someone else\'s appointment as not-found (no info leak)',
        () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p2',
        doctorId: 'd1',
        slotId: 's-old',
        start: DateTime.utc(2026, 8, 20, 9),
      );
      await seedSlot(id: 's-old', doctorId: 'd1', start: DateTime.utc(2026, 8, 20, 9), isBooked: true);
      await seedSlot(id: 's-new', doctorId: 'd1', start: newStart);

      await expectLater(
        dataSource.rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 's-new',
        ),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );

      // p2's appointment and both slots are untouched.
      final apptDoc = await firestore.collection('appointments').doc('a1').get();
      expect(apptDoc.data()!['slotId'], 's-old');
      final oldSlotDoc = await firestore.collection('slots').doc('s-old').get();
      expect(oldSlotDoc.data()!['isBooked'], isTrue);
      final newSlotDoc = await firestore.collection('slots').doc('s-new').get();
      expect(newSlotDoc.data()!['isBooked'], isFalse);
    });

    test('aborts with AppointmentAlreadyCancelledException when the '
        'appointment is already cancelled', () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's-old',
        start: DateTime.utc(2026, 8, 20, 9),
        status: 'cancelled',
      );
      await seedSlot(id: 's-old', doctorId: 'd1', start: DateTime.utc(2026, 8, 20, 9), isBooked: false);
      await seedSlot(id: 's-new', doctorId: 'd1', start: newStart);

      await expectLater(
        dataSource.rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 's-new',
        ),
        throwsA(isA<AppointmentAlreadyCancelledException>()),
      );
    });

    test('aborts with SlotUnavailableException when the old slot is no '
        'longer booked — the state a concurrent double-reschedule '
        'converges to', () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's-old',
        start: DateTime.utc(2026, 8, 20, 9),
      );
      // Another device already freed the old slot by moving this
      // appointment; this run is stale.
      await seedSlot(id: 's-old', doctorId: 'd1', start: DateTime.utc(2026, 8, 20, 9), isBooked: false);
      await seedSlot(id: 's-new', doctorId: 'd1', start: newStart);

      await expectLater(
        dataSource.rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 's-new',
        ),
        throwsA(isA<SlotUnavailableException>()),
      );

      // The appointment wasn't moved again and the new slot stayed free.
      final apptDoc = await firestore.collection('appointments').doc('a1').get();
      expect(apptDoc.data()!['slotId'], 's-old');
      final newSlotDoc = await firestore.collection('slots').doc('s-new').get();
      expect(newSlotDoc.data()!['isBooked'], isFalse);
    });
  });
}

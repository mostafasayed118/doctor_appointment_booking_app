import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/features/appointments/data/firestore_appointments_data_source.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreAppointmentsDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreAppointmentsDataSource(firestore: firestore);
  });

  /// Seeds an appointment exactly as Task 12's booking transaction writes
  /// it, plus the slot it references (the cancel transaction frees it).
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
      if (status == 'cancelled')
        'cancelledAt': Timestamp.fromDate(DateTime.utc(2026, 8, 2, 12)),
    });
  }

  Future<void> seedSlot({
    required String id,
    bool isBooked = false,
  }) async {
    await firestore.collection('slots').doc(id).set({
      'doctorId': 'd1',
      'startTime': Timestamp.fromDate(DateTime.utc(2026, 8, 20, 9)),
      'endTime': Timestamp.fromDate(DateTime.utc(2026, 8, 20, 10)),
      'isBooked': isBooked,
    });
  }

  group('getAppointments', () {
    test('returns only this patient\'s appointments, sorted by start time',
        () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's1',
        start: DateTime.utc(2026, 8, 20, 9),
      );
      await seedAppointment(
        id: 'a2',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's2',
        start: DateTime.utc(2026, 8, 18, 9),
      );
      // Another patient's appointment must not leak in.
      await seedAppointment(
        id: 'a3',
        patientId: 'p2',
        doctorId: 'd1',
        slotId: 's3',
        start: DateTime.utc(2026, 8, 19, 9),
      );

      final appointments = await dataSource.getAppointments('p1');

      expect(appointments.map((a) => a.id), ['a2', 'a1']); // sorted
      // UTC instants survive the round-trip.
      expect(appointments.first.startTime, DateTime.utc(2026, 8, 18, 9));
    });

    test('returns an empty list for a patient with no appointments', () async {
      expect(await dataSource.getAppointments('p1'), isEmpty);
    });
  });

  group('cancelAppointment', () {
    test('marks the appointment cancelled AND frees the slot atomically',
        () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's1',
        start: DateTime.utc(2026, 8, 20, 9),
      );
      await seedSlot(id: 's1', isBooked: true);

      final cancelled = await dataSource.cancelAppointment(
        patientId: 'p1',
        appointmentId: 'a1',
      );

      // The returned entity reflects what the transaction committed.
      expect(cancelled.id, 'a1');
      expect(cancelled.status, AppointmentStatus.cancelled);
      expect(cancelled.startTime, DateTime.utc(2026, 8, 20, 9)); // UTC round-trip

      // Both writes landed together.
      final apptDoc = await firestore.collection('appointments').doc('a1').get();
      expect(apptDoc.data()!['status'], 'cancelled');
      expect(apptDoc.data()!['cancelledAt'], isNotNull);

      final slotDoc = await firestore.collection('slots').doc('s1').get();
      expect(slotDoc.data()!['isBooked'], isFalse);
    });

    test('throws AppointmentAlreadyCancelledException and does not touch '
        'the slot when the appointment is already cancelled', () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 's1',
        start: DateTime.utc(2026, 8, 20, 9),
        status: 'cancelled',
      );
      await seedSlot(id: 's1', isBooked: false);

      await expectLater(
        dataSource.cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
        throwsA(isA<AppointmentAlreadyCancelledException>()),
      );

      // Nothing was re-written (and the slot was already free anyway).
      final apptDoc = await firestore.collection('appointments').doc('a1').get();
      expect(apptDoc.data()!['status'], 'cancelled');
      final slotDoc = await firestore.collection('slots').doc('s1').get();
      expect(slotDoc.data()!['isBooked'], isFalse);
    });

    test('throws a not-found FirebaseException for a missing appointment',
        () async {
      await expectLater(
        dataSource.cancelAppointment(patientId: 'p1', appointmentId: 'nope'),
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
        slotId: 's1',
        start: DateTime.utc(2026, 8, 20, 9),
      );
      await seedSlot(id: 's1', isBooked: true);

      await expectLater(
        dataSource.cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );

      // The other patient's appointment and the slot are untouched.
      final apptDoc = await firestore.collection('appointments').doc('a1').get();
      expect(apptDoc.data()!['status'], 'scheduled');
      final slotDoc = await firestore.collection('slots').doc('s1').get();
      expect(slotDoc.data()!['isBooked'], isTrue);
    });

    test('still cancels when the slot document is missing (slot is only a '
        'lock, not the record of truth)', () async {
      await seedAppointment(
        id: 'a1',
        patientId: 'p1',
        doctorId: 'd1',
        slotId: 'vanished-slot',
        start: DateTime.utc(2026, 8, 20, 9),
      );

      final cancelled = await dataSource.cancelAppointment(
        patientId: 'p1',
        appointmentId: 'a1',
      );

      expect(cancelled.status, AppointmentStatus.cancelled);
      final apptDoc = await firestore.collection('appointments').doc('a1').get();
      expect(apptDoc.data()!['status'], 'cancelled');
    });
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
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
}

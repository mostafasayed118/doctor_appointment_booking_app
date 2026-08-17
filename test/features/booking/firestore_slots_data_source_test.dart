import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/features/booking/data/firestore_slots_data_source.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreSlotsDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreSlotsDataSource(firestore: firestore);
  });

  Future<void> seedSlot(
    String id,
    String doctorId,
    DateTime start, {
    bool isBooked = false,
  }) async {
    await firestore.collection('slots').doc(id).set({
      'doctorId': doctorId,
      'startTime': Timestamp.fromDate(start),
      'endTime': Timestamp.fromDate(start.add(const Duration(hours: 1))),
      'isBooked': isBooked,
    });
  }

  group('fetchSlots', () {
    test('maps every slot for the doctor to a TimeSlot, ordered by start',
        () async {
      final t9 = DateTime.utc(2026, 8, 15, 9);
      final t10 = DateTime.utc(2026, 8, 15, 10);
      final t11 = DateTime.utc(2026, 8, 15, 11);
      await seedSlot('s9', 'd1', t9);
      await seedSlot('s11', 'd1', t11);
      await seedSlot('s10', 'd1', t10);

      final slots = await dataSource.fetchSlots('d1');

      expect(slots.map((s) => s.id), ['s9', 's10', 's11']);
      expect(slots.first.startTime, t9);
      expect(slots.first.endTime, t10);
      expect(slots.first.isBooked, isFalse);
    });

    test('excludes slots belonging to other doctors', () async {
      await seedSlot('mine', 'd1', DateTime.utc(2026, 8, 15, 9));
      await seedSlot('theirs', 'd2', DateTime.utc(2026, 8, 15, 9));

      final slots = await dataSource.fetchSlots('d1');

      expect(slots.map((s) => s.id), ['mine']);
    });

    test('returns an empty list when the doctor has no slots', () async {
      expect(await dataSource.fetchSlots('nobody'), isEmpty);
    });

    test('preserves the isBooked flag', () async {
      await seedSlot(
        'taken',
        'd1',
        DateTime.utc(2026, 8, 15, 9),
        isBooked: true,
      );

      final slots = await dataSource.fetchSlots('d1');

      expect(slots.single.isBooked, isTrue);
    });
  });
}

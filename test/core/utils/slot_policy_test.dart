import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/time_slot.dart';
import 'package:doctor_appointment_booking_app/core/utils/slot_policy.dart';

void main() {
  const policy = SlotPolicy();

  // Fixed "now" so the tests are deterministic — no wall-clock dependence.
  final now = DateTime.utc(2026, 8, 13, 12, 0);

  TimeSlot slot({
    DateTime? start,
    bool isBooked = false,
  }) {
    final s = start ?? DateTime.utc(2026, 8, 13, 14, 0);
    return TimeSlot(
      id: 'slot-1',
      doctorId: 'doctor-1',
      startTime: s,
      endTime: s.add(const Duration(hours: 1)),
      isBooked: isBooked,
    );
  }

  group('SlotPolicy.isInPast', () {
    test('returns true for a slot that started in the past', () {
      final past = slot(start: DateTime.utc(2026, 8, 13, 10, 0));

      expect(policy.isInPast(past, now), isTrue);
    });

    test('returns false for a slot that starts in the future', () {
      final future = slot(start: DateTime.utc(2026, 8, 13, 14, 0));

      expect(policy.isInPast(future, now), isFalse);
    });

    test('returns true for a slot starting exactly at now', () {
      final exactlyNow = slot(
        start: DateTime.utc(2026, 8, 13, 12, 0),
      );

      // A slot that starts right now is treated as no longer bookable.
      expect(policy.isInPast(exactlyNow, now), isTrue);
    });
  });

  group('SlotPolicy.canBook', () {
    test('returns true for a free future slot', () {
      final future = slot();

      expect(policy.canBook(future, now), isTrue);
    });

    test('returns false for an already-booked future slot', () {
      final futureBooked = slot(isBooked: true);

      expect(policy.canBook(futureBooked, now), isFalse);
    });

    test('returns false for a free past slot', () {
      final past = slot(start: DateTime.utc(2026, 8, 13, 10, 0));

      expect(policy.canBook(past, now), isFalse);
    });
  });
}
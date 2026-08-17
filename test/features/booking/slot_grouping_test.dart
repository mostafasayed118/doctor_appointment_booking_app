import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/time_slot.dart';
import 'package:doctor_appointment_booking_app/features/booking/presentation/slot_grouping.dart';

TimeSlot slot(
  String id, {
  required DateTime start,
  bool isBooked = false,
}) =>
    TimeSlot(
      id: id,
      doctorId: 'd1',
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
      isBooked: isBooked,
    );

void main() {
  // A fixed "now" keeps past-slot filtering deterministic regardless of
  // when the test runs. Times are local (the group key is the LOCAL date).
  final now = DateTime(2026, 8, 14, 12);

  group('groupSlotsByDay', () {
    test('groups slots by local calendar date, chronologically', () {
      // All after `now` (Aug 14) so nothing is filtered out as past.
      final monday9 = DateTime(2026, 8, 17, 9);
      final monday10 = DateTime(2026, 8, 17, 10);
      final tuesday9 = DateTime(2026, 8, 18, 9);

      final days = groupSlotsByDay(
        [tuesday9, monday10, monday9].map((t) => slot(t.toString(), start: t)).toList(),
        now: now,
      );

      expect(days, hasLength(2));
      expect(days[0].day, DateTime(2026, 8, 17));
      expect(days[0].slots.map((s) => s.startTime), [monday9, monday10]);
      expect(days[1].day, DateTime(2026, 8, 18));
    });

    test('excludes slots in the past', () {
      final past = slot('past', start: now.subtract(const Duration(hours: 1)));
      final future = slot('future', start: now.add(const Duration(hours: 1)));

      final days = groupSlotsByDay([past, future], now: now);

      expect(days, hasLength(1));
      expect(days.single.slots.map((s) => s.id), ['future']);
    });

    test('excludes booked slots', () {
      final free = slot('free', start: now.add(const Duration(hours: 1)));
      final taken = slot(
        'taken',
        start: now.add(const Duration(hours: 2)),
        isBooked: true,
      );

      final days = groupSlotsByDay([free, taken], now: now);

      expect(days.single.slots.map((s) => s.id), ['free']);
    });

    test('keeps a day that has slot docs but zero bookable slots', () {
      final taken = slot(
        'taken',
        start: now.add(const Duration(hours: 1)),
        isBooked: true,
      );

      final days = groupSlotsByDay([taken], now: now);

      expect(days, hasLength(1));
      expect(days.single.day, DateTime(2026, 8, 14));
      expect(days.single.hasSlots, isFalse);
    });

    test('returns no days for an empty slot list', () {
      expect(groupSlotsByDay(const [], now: now), isEmpty);
    });

    test('sorts a day’s slots by start time', () {
      final t11 = slot('t11', start: now.add(const Duration(hours: 3)));
      final t9 = slot('t9', start: now.add(const Duration(hours: 1)));
      final t10 = slot('t10', start: now.add(const Duration(hours: 2)));

      final days = groupSlotsByDay([t11, t9, t10], now: now);

      expect(days.single.slots.map((s) => s.id), ['t9', 't10', 't11']);
    });
  });
}

import 'package:equatable/equatable.dart';

import '../../../core/entities/time_slot.dart';
import '../../../core/utils/slot_policy.dart';

/// One selectable day in the booking screen: the calendar date plus every
/// slot that is still bookable on it.
///
/// Days with slot *documents* but zero bookable slots are kept (with an
/// empty [slots]) so the UI can show "no availability" — a fully-booked
/// day must not silently vanish. Days with no slot documents at all (e.g.
/// a Sunday the clinic is closed) never appear.
class SlotDay extends Equatable {
  const SlotDay({required this.day, required this.slots});

  /// The calendar date (local time), with the time component zeroed.
  final DateTime day;

  /// Bookable slots on this day, ordered by start time.
  final List<TimeSlot> slots;

  bool get hasSlots => slots.isNotEmpty;

  @override
  List<Object?> get props => [day, slots];
}

/// Groups [slots] into [SlotDay]s for the booking screen.
///
/// Pure and deterministic: [now] is injected so tests can control the
/// past-boundary. Rules:
/// - Slots are grouped by their LOCAL calendar date (stored instants map
///   to the day the patient actually sees).
/// - A day is kept if it has at least one slot that is not in the past;
///   a past day is dropped entirely.
/// - Within a kept day, only bookable slots (not past, not booked) are
///   listed via [SlotPolicy.canBook] — the pre-flight check; the booking
///   transaction re-checks authoritatively. A future day whose slots are
///   all booked stays visible with an empty list so the UI can say "no
///   availability" instead of silently vanishing.
/// - Days are returned chronologically; each day's slots are sorted by
///   start time.
List<SlotDay> groupSlotsByDay(
  List<TimeSlot> slots, {
  required DateTime now,
  SlotPolicy policy = const SlotPolicy(),
}) {
  final byDay = <DateTime, List<TimeSlot>>{};

  for (final slot in slots) {
    final local = slot.startTime.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    byDay.putIfAbsent(day, () => []).add(slot);
  }

  final days = byDay.keys.toList()..sort();
  return [
    for (final day in days)
      if (byDay[day]!.any((s) => !policy.isInPast(s, now)))
        SlotDay(
          day: day,
          slots: byDay[day]!
              .where((s) => policy.canBook(s, now))
              .toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime)),
        ),
  ];
}

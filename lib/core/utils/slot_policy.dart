import '../entities/time_slot.dart';

/// Pure rules for what makes a [TimeSlot] bookable.
///
/// This is intentionally free of any Firebase dependency so it can be unit
/// tested in isolation. The repository re-checks these rules *inside* the
/// Firestore transaction (Task 12) — this class is the "pre-flight" check,
/// and the transaction is the authoritative one.
class SlotPolicy {
  const SlotPolicy();

  /// A slot is in the past if its start time is not strictly after [now].
  ///
  /// A slot starting exactly at [now] is treated as already in the past —
  /// you can't book a slot that starts this instant.
  bool isInPast(TimeSlot slot, DateTime now) => !slot.startTime.isAfter(now);

  /// A slot can be booked if it is not in the past and not already booked.
  bool canBook(TimeSlot slot, DateTime now) =>
      !isInPast(slot, now) && !slot.isBooked;
}
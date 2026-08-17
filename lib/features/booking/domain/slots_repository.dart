import '../../../core/entities/time_slot.dart';
import '../../../core/error/result.dart';

/// Contract the booking feature depends on for reading bookable slots.
///
/// The domain defines WHAT slot reading does; the data layer decides HOW
/// (Firestore today, anything else tomorrow). Cubits depend on this
/// interface, never on a concrete implementation — that's what makes the
/// cubits unit-testable and keeps Firestore out of presentation.
abstract interface class SlotsRepository {
  /// Every slot document for [doctorId], unfiltered — past and booked
  /// slots are included. The presentation layer decides what is bookable
  /// via [SlotPolicy], so the repository stays a dumb reader.
  Future<Result<List<TimeSlot>>> getSlots(String doctorId);
}

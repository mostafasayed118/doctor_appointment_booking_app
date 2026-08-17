import '../../../core/entities/appointment.dart';
import '../../../core/error/result.dart';

/// Contract for creating appointments atomically.
///
/// The domain defines WHAT booking does; the data layer decides HOW (a
/// Firestore transaction today). Cubits depend on this interface, never on
/// a concrete implementation — that's what makes them unit-testable and
/// keeps Firestore out of presentation.
abstract interface class BookingRepository {
  /// Books [slotId] for [patientId] in a single atomic unit of work: the
  /// slot is marked booked and the appointment is created together, so a
  /// slot can never end up double-booked.
  ///
  /// Only [slotId] + [patientId] are passed: the slot's doctor, times, and
  /// bookability are read from the authoritative document inside the
  /// transaction, never trusted from a caller-supplied copy.
  ///
  /// Failures are typed:
  /// - [SlotUnavailableError] when the slot exists but can't be booked
  ///   (already taken, or its start time has passed).
  /// - [NotFoundError] when the slot document does not exist.
  /// - [NetworkError]/[ServerError]/[UnexpectedError] via the error mapper
  ///   for SDK-level failures.
  Future<Result<Appointment>> bookSlot({
    required String patientId,
    required String slotId,
  });
}

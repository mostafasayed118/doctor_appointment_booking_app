import '../../../core/entities/appointment.dart';
import '../../../core/error/result.dart';

/// Contract the appointments feature depends on.
///
/// The domain defines WHAT appointments can do; the data layer decides HOW
/// (Firestore today, anything else tomorrow). Cubits depend on this
/// interface, never on a concrete implementation — that's what makes the
/// cubits unit-testable and keeps Firestore out of presentation.
abstract interface class AppointmentsRepository {
  /// Every appointment for [patientId], sorted by start time. Cancelled and
  /// completed appointments are included — the presentation layer splits
  /// them into upcoming/past.
  Future<Result<List<Appointment>>> getAppointments(String patientId);

  /// Cancels [appointmentId] on behalf of [patientId], freeing its slot.
  ///
  /// Fails with [AppointmentAlreadyCancelledError] when the appointment is
  /// already cancelled, and [NotFoundError] when it doesn't exist (or isn't
  /// this patient's — treated as non-existent so the check leaks nothing).
  Future<Result<Appointment>> cancelAppointment({
    required String patientId,
    required String appointmentId,
  });
}

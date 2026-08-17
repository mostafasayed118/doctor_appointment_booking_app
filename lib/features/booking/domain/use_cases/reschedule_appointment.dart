import '../../../../core/entities/appointment.dart';
import '../../../../core/error/result.dart';
import '../booking_repository.dart';

/// Moves an appointment to a new slot, freeing the old one (Task 14).
///
/// Thin on purpose: it exists to give the presentation layer a named
/// operation instead of calling the repository directly, matching the
/// BookSlot/GetSlots pattern in the booking feature.
class RescheduleAppointment {
  const RescheduleAppointment(this._repository);

  final BookingRepository _repository;

  Future<Result<Appointment>> call({
    required String patientId,
    required String appointmentId,
    required String newSlotId,
  }) => _repository.rescheduleAppointment(
    patientId: patientId,
    appointmentId: appointmentId,
    newSlotId: newSlotId,
  );
}

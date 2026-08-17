import '../../../../core/entities/appointment.dart';
import '../../../../core/error/result.dart';
import '../appointments_repository.dart';

/// Cancels an appointment, freeing its slot so other patients can book it.
class CancelAppointment {
  const CancelAppointment(this._repository);

  final AppointmentsRepository _repository;

  Future<Result<Appointment>> call({
    required String patientId,
    required String appointmentId,
  }) =>
      _repository.cancelAppointment(
        patientId: patientId,
        appointmentId: appointmentId,
      );
}

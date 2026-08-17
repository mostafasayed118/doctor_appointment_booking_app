import '../../../../core/entities/appointment.dart';
import '../../../../core/error/result.dart';
import '../appointments_repository.dart';

/// Loads every appointment for a patient (upcoming and past included — the
/// presentation layer splits them with the device clock).
class GetAppointments {
  const GetAppointments(this._repository);

  final AppointmentsRepository _repository;

  Future<Result<List<Appointment>>> call(String patientId) =>
      _repository.getAppointments(patientId);
}

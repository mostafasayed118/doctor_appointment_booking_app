import '../../../core/entities/appointment.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../../data/error/firebase_error_mapper.dart';
import '../domain/appointments_repository.dart';
import 'firestore_appointments_data_source.dart';

/// Production [AppointmentsRepository]: delegates to
/// [FirestoreAppointmentsDataSource] and maps thrown exceptions to typed
/// [AppError]s at THIS boundary. Cubits and widgets never see an exception
/// — only the [Result] contract from core.
///
/// Our own business rule ([AppointmentAlreadyCancelledException]) is caught
/// first and becomes [AppointmentAlreadyCancelledError]; SDK exceptions
/// (including the `not-found` code the data source raises for a missing or
/// not-owned appointment) go through [FirebaseErrorMapper].
class AppointmentsRepositoryImpl implements AppointmentsRepository {
  AppointmentsRepositoryImpl({
    required this._dataSource,
    this._mapper = const FirebaseErrorMapper(),
  });

  final FirestoreAppointmentsDataSource _dataSource;
  final FirebaseErrorMapper _mapper;

  @override
  Future<Result<List<Appointment>>> getAppointments(String patientId) async {
    try {
      final appointments = await _dataSource.getAppointments(patientId);
      return Success(appointments);
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }

  @override
  Future<Result<Appointment>> cancelAppointment({
    required String patientId,
    required String appointmentId,
  }) async {
    try {
      final appointment = await _dataSource.cancelAppointment(
        patientId: patientId,
        appointmentId: appointmentId,
      );
      return Success(appointment);
    } on AppointmentAlreadyCancelledException {
      return const Failure(AppointmentAlreadyCancelledError());
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }
}

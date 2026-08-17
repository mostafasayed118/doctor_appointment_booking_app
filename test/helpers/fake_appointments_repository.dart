import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/appointments/domain/appointments_repository.dart';

/// In-memory [AppointmentsRepository] for widget/router tests.
///
/// Registered into GetIt (overriding the real Firestore-backed registration)
/// by the test harness, so router-level tests can reach /appointments with
/// the REAL cubit chain over fake data — the real data source constructs
/// `FirebaseFirestore.instance`, which blocks on a platform channel that
/// never answers in unit tests.
class FakeAppointmentsRepository implements AppointmentsRepository {
  FakeAppointmentsRepository({this.appointments = const [], this.onCancel});

  /// The appointments the fake serves; `getAppointments` filters by patient
  /// and sorts by start time, like the real data source.
  final List<Appointment> appointments;

  /// Optional handler so tests can force failures; defaults to success.
  final Future<Result<Appointment>> Function(
    String patientId,
    String appointmentId,
  )? onCancel;

  @override
  Future<Result<List<Appointment>>> getAppointments(String patientId) async {
    final mine = appointments
        .where((a) => a.patientId == patientId)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return Success(mine);
  }

  @override
  Future<Result<Appointment>> cancelAppointment({
    required String patientId,
    required String appointmentId,
  }) {
    final handler = onCancel;
    if (handler != null) return handler(patientId, appointmentId);
    final appointment = appointments.firstWhere((a) => a.id == appointmentId);
    final cancelled = Appointment(
      id: appointment.id,
      patientId: appointment.patientId,
      doctorId: appointment.doctorId,
      slotId: appointment.slotId,
      startTime: appointment.startTime,
      endTime: appointment.endTime,
      status: AppointmentStatus.cancelled,
      createdAt: appointment.createdAt,
      cancelledAt: DateTime.now(),
    );
    return Future.value(Success(cancelled));
  }
}

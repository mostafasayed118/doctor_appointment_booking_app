import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/booking/domain/booking_repository.dart';

/// In-memory [BookingRepository] for widget/router tests.
///
/// Registered into GetIt (overriding the real Firestore-backed registration)
/// by the test harness, so router-level tests can reach the confirmation
/// route with the REAL cubit chain over fake data — the real data source
/// constructs `FirebaseFirestore.instance`, which blocks on a platform
/// channel that never answers in unit tests.
class FakeBookingRepository implements BookingRepository {
  FakeBookingRepository({this.onBookSlot});

  /// Optional handler so tests can force failures; defaults to success.
  final Future<Result<Appointment>> Function(String patientId, String slotId)?
  onBookSlot;

  @override
  Future<Result<Appointment>> bookSlot({
    required String patientId,
    required String slotId,
  }) {
    final handler = onBookSlot;
    if (handler != null) return handler(patientId, slotId);
    return Future.value(Success(_appointment(patientId, slotId)));
  }

  Appointment _appointment(String patientId, String slotId) => Appointment(
    id: 'appt-1',
    patientId: patientId,
    doctorId: 'd1',
    slotId: slotId,
    startTime: DateTime.utc(2026, 8, 20, 9),
    endTime: DateTime.utc(2026, 8, 20, 10),
    status: AppointmentStatus.scheduled,
    createdAt: DateTime.now(),
  );
}

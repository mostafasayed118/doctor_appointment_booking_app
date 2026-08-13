import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/doctors_repository.dart';

/// In-memory [DoctorsRepository] for widget/router tests.
///
/// Registered into GetIt (overriding the real Firestore-backed registration)
/// by the test harness, so router-level tests can navigate to /doctors with
/// the REAL cubit chain over fake data — the real data source constructs
/// `FirebaseFirestore.instance`, which blocks on a platform channel that
/// never answers in unit tests.
class FakeDoctorsRepository implements DoctorsRepository {
  FakeDoctorsRepository({this.doctors = const []});

  final List<Doctor> doctors;

  @override
  Future<Result<List<Doctor>>> getDoctors() async => Success(doctors);

  @override
  Future<Result<Doctor>> getDoctor(String id) async {
    for (final doctor in doctors) {
      if (doctor.id == id) return Success(doctor);
    }
    return Failure(NotFoundError(message: 'Doctor $id was not found.'));
  }
}

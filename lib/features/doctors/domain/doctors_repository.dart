import '../../../core/entities/doctor.dart';
import '../../../core/error/result.dart';

/// Contract the doctors feature depends on.
///
/// The domain defines WHAT doctors can do; the data layer decides HOW
/// (Firestore today, anything else tomorrow). Cubits depend on this
/// interface, never on a concrete implementation — that's what makes the
/// cubits unit-testable and keeps Firestore out of presentation.
abstract interface class DoctorsRepository {
  /// All doctors, as displayed in the browse list.
  Future<Result<List<Doctor>>> getDoctors();

  /// A single doctor by id; a missing doctor is a `NotFoundError` failure.
  Future<Result<Doctor>> getDoctor(String id);
}

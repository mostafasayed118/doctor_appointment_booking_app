import '../../../../core/entities/appointment.dart';
import '../../../../core/error/result.dart';
import '../booking_repository.dart';

/// Books a slot for the signed-in patient (Task 12).
///
/// Thin on purpose: it exists to give the presentation layer a named
/// operation instead of calling the repository directly, matching the
/// GetSlots/GetDoctor pattern in the other features.
class BookSlot {
  const BookSlot(this._repository);

  final BookingRepository _repository;

  Future<Result<Appointment>> call({
    required String patientId,
    required String slotId,
  }) => _repository.bookSlot(patientId: patientId, slotId: slotId);
}

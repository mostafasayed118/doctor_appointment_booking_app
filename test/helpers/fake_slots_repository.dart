import 'package:doctor_appointment_booking_app/core/entities/time_slot.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/booking/domain/slots_repository.dart';

/// In-memory [SlotsRepository] for widget/router tests.
///
/// Registered into GetIt (overriding the real Firestore-backed registration)
/// by the test harness, so router-level tests can navigate to the booking
/// screen with the REAL cubit chain over fake data — the real data source
/// constructs `FirebaseFirestore.instance`, which blocks on a platform
/// channel that never answers in unit tests.
class FakeSlotsRepository implements SlotsRepository {
  FakeSlotsRepository({this.slotsByDoctor = const {}});

  /// Slots keyed by doctor id.
  final Map<String, List<TimeSlot>> slotsByDoctor;

  @override
  Future<Result<List<TimeSlot>>> getSlots(String doctorId) async =>
      Success(slotsByDoctor[doctorId] ?? const []);
}

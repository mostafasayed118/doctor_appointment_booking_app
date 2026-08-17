import '../../../../core/entities/time_slot.dart';
import '../../../../core/error/result.dart';
import '../slots_repository.dart';

/// Loads every slot document for a doctor (past/booked included — the
/// presentation layer filters with [SlotPolicy]).
class GetSlots {
  const GetSlots(this._repository);

  final SlotsRepository _repository;

  Future<Result<List<TimeSlot>>> call(String doctorId) =>
      _repository.getSlots(doctorId);
}

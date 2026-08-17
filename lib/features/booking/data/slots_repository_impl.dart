import '../../../core/entities/time_slot.dart';
import '../../../core/error/result.dart';
import '../../../data/error/firebase_error_mapper.dart';
import '../domain/slots_repository.dart';
import 'firestore_slots_data_source.dart';

/// Production [SlotsRepository]: delegates to [FirestoreSlotsDataSource]
/// and maps every thrown SDK exception to a typed [AppError] at THIS
/// boundary. Cubits and widgets never see a Firebase exception — only the
/// [Result] contract from core.
class SlotsRepositoryImpl implements SlotsRepository {
  SlotsRepositoryImpl({
    required this._dataSource,
    this._mapper = const FirebaseErrorMapper(),
  });

  final FirestoreSlotsDataSource _dataSource;
  final FirebaseErrorMapper _mapper;

  @override
  Future<Result<List<TimeSlot>>> getSlots(String doctorId) async {
    try {
      return Success(await _dataSource.fetchSlots(doctorId));
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }
}

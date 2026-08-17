import '../../../core/entities/appointment.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../../data/error/firebase_error_mapper.dart';
import '../domain/booking_repository.dart';
import 'firestore_booking_data_source.dart';

/// Production [BookingRepository]: delegates to
/// [FirestoreBookingDataSource] and maps thrown exceptions to typed
/// [AppError]s at THIS boundary. Cubits and widgets never see an exception
/// — only the [Result] contract from core.
///
/// Our own business rule ([SlotUnavailableException]) is caught first and
/// becomes [SlotUnavailableError]; SDK exceptions (including the
/// `not-found` code the data source raises for a missing slot) go through
/// [FirebaseErrorMapper].
class BookingRepositoryImpl implements BookingRepository {
  BookingRepositoryImpl({
    required this._dataSource,
    this._mapper = const FirebaseErrorMapper(),
  });

  final FirestoreBookingDataSource _dataSource;
  final FirebaseErrorMapper _mapper;

  @override
  Future<Result<Appointment>> bookSlot({
    required String patientId,
    required String slotId,
  }) async {
    try {
      final appointment = await _dataSource.bookSlot(
        patientId: patientId,
        slotId: slotId,
      );
      return Success(appointment);
    } on SlotUnavailableException {
      return const Failure(SlotUnavailableError());
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }
}

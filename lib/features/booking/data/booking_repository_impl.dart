import '../../../core/entities/appointment.dart';
import '../../../core/error/app_error.dart';
import '../../../core/error/result.dart';
import '../../../data/error/firebase_error_mapper.dart';
import '../../appointments/data/firestore_appointments_data_source.dart'
    show AppointmentAlreadyCancelledException;
import '../domain/booking_repository.dart';
import 'firestore_booking_data_source.dart';

/// Production [BookingRepository]: delegates to
/// [FirestoreBookingDataSource] and maps thrown exceptions to typed
/// [AppError]s at THIS boundary. Cubits and widgets never see an exception
/// — only the [Result] contract from core.
///
/// Our own business rules are caught first and mapped directly —
/// [SlotUnavailableException] → [SlotUnavailableError], and (for
/// reschedule) [AppointmentAlreadyCancelledException] →
/// [AppointmentAlreadyCancelledError]; SDK exceptions (including the
/// `not-found` code the data source raises for a missing slot/appointment)
/// go through [FirebaseErrorMapper].
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

  @override
  Future<Result<Appointment>> rescheduleAppointment({
    required String patientId,
    required String appointmentId,
    required String newSlotId,
  }) async {
    try {
      final appointment = await _dataSource.rescheduleAppointment(
        patientId: patientId,
        appointmentId: appointmentId,
        newSlotId: newSlotId,
      );
      return Success(appointment);
    } on SlotUnavailableException {
      // The new slot was taken/past, or the old slot is no longer booked
      // (a concurrent reschedule already moved this appointment).
      return const Failure(SlotUnavailableError());
    } on AppointmentAlreadyCancelledException {
      return const Failure(AppointmentAlreadyCancelledError());
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }
}

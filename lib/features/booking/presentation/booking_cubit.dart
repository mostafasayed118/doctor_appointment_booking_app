import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/time_slot.dart';
import '../../../core/error/result.dart';
import '../domain/use_cases/book_slot.dart';
import 'booking_state.dart';

/// Owns the booking confirmation flow.
///
/// The route provides this cubit and immediately calls [confirm]; the
/// confirmation page renders whatever state results. Concurrency safety is
/// the data layer's job (the transaction) — this cubit just reports the
/// outcome as Loading → Success/Error.
class BookingCubit extends Cubit<BookingState> {
  BookingCubit({required this._bookSlot}) : super(const BookingInitial());

  final BookSlot _bookSlot;

  String? _lastPatientId;
  TimeSlot? _lastSlot;

  /// Books [slot] for [patientId].
  Future<void> confirm({
    required String patientId,
    required TimeSlot slot,
  }) async {
    _lastPatientId = patientId;
    _lastSlot = slot;
    emit(const BookingConfirming());
    final result = await _bookSlot(patientId: patientId, slotId: slot.id);
    switch (result) {
      case Success(:final value):
        emit(BookingConfirmed(value));
      case Failure(:final error):
        emit(BookingError(error));
    }
  }

  /// Re-runs the last confirm. Right for transient (network) failures; on
  /// [SlotUnavailableError] it will fail again, and the AppBar back button
  /// is the "go refresh the slot list" affordance.
  void retry() {
    final patientId = _lastPatientId;
    final slot = _lastSlot;
    if (patientId != null && slot != null) {
      confirm(patientId: patientId, slot: slot);
    }
  }

  /// Clears the outcome so the screen can be re-used for a new attempt.
  void reset() => emit(const BookingInitial());
}

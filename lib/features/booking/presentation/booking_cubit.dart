import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/time_slot.dart';
import '../../../core/error/result.dart';
import '../domain/use_cases/book_slot.dart';
import '../domain/use_cases/reschedule_appointment.dart';
import 'booking_state.dart';

/// Owns the booking confirmation flow.
///
/// The route provides this cubit and immediately calls [confirm]; the
/// confirmation page renders whatever state results. Concurrency safety is
/// the data layer's job (the transaction) — this cubit just reports the
/// outcome as Loading → Success/Error.
class BookingCubit extends Cubit<BookingState> {
  BookingCubit({
    required this._bookSlot,
    required this._rescheduleAppointment,
  }) : super(const BookingInitial());

  final BookSlot _bookSlot;
  final RescheduleAppointment _rescheduleAppointment;

  String? _lastPatientId;
  TimeSlot? _lastSlot;
  String? _lastAppointmentId;
  TimeSlot? _lastNewSlot;

  /// Books [slot] for [patientId].
  Future<void> confirm({
    required String patientId,
    required TimeSlot slot,
  }) async {
    _lastPatientId = patientId;
    _lastSlot = slot;
    _lastAppointmentId = null;
    _lastNewSlot = null;
    emit(const BookingConfirming());
    final result = await _bookSlot(patientId: patientId, slotId: slot.id);
    switch (result) {
      case Success(:final value):
        emit(BookingConfirmed(value));
      case Failure(:final error):
        emit(BookingError(error));
    }
  }

  /// Moves [appointmentId] to [newSlot] for [patientId] (Task 14).
  Future<void> reschedule({
    required String patientId,
    required String appointmentId,
    required TimeSlot newSlot,
  }) async {
    _lastPatientId = patientId;
    _lastAppointmentId = appointmentId;
    _lastNewSlot = newSlot;
    _lastSlot = null;
    emit(const BookingConfirming());
    final result = await _rescheduleAppointment(
      patientId: patientId,
      appointmentId: appointmentId,
      newSlotId: newSlot.id,
    );
    switch (result) {
      case Success(:final value):
        emit(BookingRescheduled(value));
      case Failure(:final error):
        emit(BookingError(error));
    }
  }

  /// Re-runs the last confirm/reschedule. Right for transient (network)
  /// failures; on [SlotUnavailableError] it will fail again, and the AppBar
  /// back button is the "go refresh the slot list" affordance.
  void retry() {
    final patientId = _lastPatientId;
    if (patientId != null && _lastSlot != null) {
      confirm(patientId: patientId, slot: _lastSlot!);
    } else if (patientId != null &&
        _lastAppointmentId != null &&
        _lastNewSlot != null) {
      reschedule(
        patientId: patientId,
        appointmentId: _lastAppointmentId!,
        newSlot: _lastNewSlot!,
      );
    }
  }

  /// Clears the outcome so the screen can be re-used for a new attempt.
  void reset() => emit(const BookingInitial());
}

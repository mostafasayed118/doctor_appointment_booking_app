import 'package:equatable/equatable.dart';

import '../../../core/entities/appointment.dart';
import '../../../core/error/app_error.dart';

/// All the states the booking/confirmation screen can be in.
///
/// Sealed so the compiler knows every variant — exhaustive `switch`
/// matching is enforced, and no new state can be invented outside this file.
sealed class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet (route entered, confirm not started).
final class BookingInitial extends BookingState {
  const BookingInitial();
}

/// The booking transaction is in flight.
final class BookingConfirming extends BookingState {
  const BookingConfirming();
}

/// The appointment was created — show the success screen.
final class BookingConfirmed extends BookingState {
  const BookingConfirmed(this.appointment);

  final Appointment appointment;

  @override
  List<Object?> get props => [appointment];
}

/// The appointment was moved to a new slot (Task 14) — show the reschedule
/// success screen. Additive on purpose: Task 12's states are untouched, so
/// the booking flow's tests keep passing unchanged.
final class BookingRescheduled extends BookingState {
  const BookingRescheduled(this.appointment);

  final Appointment appointment;

  @override
  List<Object?> get props => [appointment];
}

/// Booking failed — slot taken/gone, network, or server error.
final class BookingError extends BookingState {
  const BookingError(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];
}

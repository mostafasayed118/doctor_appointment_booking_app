import 'package:equatable/equatable.dart';

import '../../../core/entities/appointment.dart';
import '../../../core/entities/doctor.dart';
import '../../../core/error/app_error.dart';

/// All the states the appointments screen can be in.
///
/// Sealed so the compiler knows every variant — exhaustive `switch`
/// matching is enforced, and no new state can be invented outside this file.
sealed class AppointmentsState extends Equatable {
  const AppointmentsState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet (route entered, load not started).
final class AppointmentsInitial extends AppointmentsState {
  const AppointmentsInitial();
}

/// The appointments (and the doctor lookup) are being loaded.
final class AppointmentsLoading extends AppointmentsState {
  const AppointmentsLoading();
}

/// The load failed.
final class AppointmentsError extends AppointmentsState {
  const AppointmentsError(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];
}

/// Appointments are loaded and split into [upcoming] (still scheduled and
/// not yet started) and [past] (cancelled, completed, or already started).
///
/// [doctorsById] maps doctor ids to [Doctor]s so cards can show name/photo
/// without a per-card fetch (the appointment doc stores only `doctorId`).
/// [cancellingId] is the appointment whose cancel transaction is in flight
/// — non-null disables the cancel buttons so a double-tap can't fire two
/// transactions.
final class AppointmentsLoaded extends AppointmentsState {
  const AppointmentsLoaded({
    required this.upcoming,
    required this.past,
    required this.doctorsById,
    this.cancellingId,
  });

  final List<Appointment> upcoming;
  final List<Appointment> past;
  final Map<String, Doctor> doctorsById;
  final String? cancellingId;

  @override
  List<Object?> get props => [upcoming, past, doctorsById, cancellingId];
}

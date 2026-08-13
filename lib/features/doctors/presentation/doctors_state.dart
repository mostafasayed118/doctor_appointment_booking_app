import 'package:equatable/equatable.dart';

import '../../../core/entities/doctor.dart';
import '../../../core/error/app_error.dart';

/// All the states the doctors browse list can be in.
///
/// Sealed so the compiler knows every variant — exhaustive `switch`
/// matching is enforced, and no new state can be invented outside this file.
sealed class DoctorsState extends Equatable {
  const DoctorsState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet.
final class DoctorsInitial extends DoctorsState {
  const DoctorsInitial();
}

/// The initial load is in flight.
final class DoctorsLoading extends DoctorsState {
  const DoctorsLoading();
}

/// Doctors are loaded. Carries the FULL list (drives the specialty filter
/// bar) plus the precomputed [filteredDoctors] after search/filter, so the
/// UI renders one list and tests assert exact filter output.
final class DoctorsLoaded extends DoctorsState {
  const DoctorsLoaded({
    required this.allDoctors,
    required this.filteredDoctors,
    this.query = '',
    this.selectedSpecialty,
  });

  final List<Doctor> allDoctors;
  final List<Doctor> filteredDoctors;
  final String query;
  final String? selectedSpecialty;

  /// True when nothing matches the current search/filter (as opposed to
  /// there being no doctors at all) — the UI shows a different empty copy.
  bool get isFiltering => query.isNotEmpty || selectedSpecialty != null;

  @override
  List<Object?> get props => [allDoctors, filteredDoctors, query, selectedSpecialty];
}

/// The load failed.
final class DoctorsError extends DoctorsState {
  const DoctorsError(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];
}

/// All the states the doctor profile screen can be in.
sealed class DoctorProfileState extends Equatable {
  const DoctorProfileState();

  @override
  List<Object?> get props => [];
}

final class DoctorProfileInitial extends DoctorProfileState {
  const DoctorProfileInitial();
}

final class DoctorProfileLoading extends DoctorProfileState {
  const DoctorProfileLoading();
}

final class DoctorProfileLoaded extends DoctorProfileState {
  const DoctorProfileLoaded(this.doctor);

  final Doctor doctor;

  @override
  List<Object?> get props => [doctor];
}

final class DoctorProfileError extends DoctorProfileState {
  const DoctorProfileError(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];
}

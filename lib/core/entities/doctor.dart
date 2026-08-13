import 'package:equatable/equatable.dart';

/// A doctor's profile, as displayed to patients.
///
/// This is a shared entity: it's used by the doctors list, the doctor
/// profile page, and the booking/appointments flows, so it lives in
/// `core/entities` rather than a single feature's `domain/`.
///
/// Instances are immutable and value-comparable via [Equatable] so Cubit
/// states holding doctors can be compared with `==` (needed for tests and
/// to avoid spurious UI rebuilds).
class Doctor extends Equatable {
  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.bio,
    required this.rating,
    required this.clinicAddress,
    required this.photoUrl,
  });

  final String id;
  final String name;

  /// The doctor's specialty, e.g. "Cardiology". Used as a filter value.
  final String specialty;
  final String bio;

  /// Read-only aggregate rating, 0.0–5.0. Patients do not submit ratings in
  /// Phase 1.
  final double rating;
  final String clinicAddress;
  final String photoUrl;

  @override
  List<Object?> get props => [
        id,
        name,
        specialty,
        bio,
        rating,
        clinicAddress,
        photoUrl,
      ];
}
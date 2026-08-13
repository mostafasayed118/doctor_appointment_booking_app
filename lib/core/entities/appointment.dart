import 'package:equatable/equatable.dart';

/// The lifecycle status of an appointment.
///
/// Mirrors the Firestore `appointments.status` string field. Kept as a Dart
/// enum so values are type-safe and exhaustive `switch` matching is
/// enforced. The storage format is the lowercase [name] of the enum.
enum AppointmentStatus {
  scheduled,
  cancelled,
  completed,
}

/// A patient's booked appointment.
///
/// Shared across the booking and appointments features, so it lives in
/// `core/entities`. `startTime`/`endTime` are deliberately copied from the
/// slot at booking time (a calculated denormalization) so the appointments
/// list can sort/group without joining to the `slots` collection.
class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
  });

  final String id;
  final String patientId;
  final String doctorId;
  final String slotId;
  final DateTime startTime;
  final DateTime endTime;
  final AppointmentStatus status;
  final DateTime createdAt;

  /// Set when [status] becomes [AppointmentStatus.cancelled].
  final DateTime? cancelledAt;

  @override
  List<Object?> get props => [
        id,
        patientId,
        doctorId,
        slotId,
        startTime,
        endTime,
        status,
        createdAt,
        cancelledAt,
      ];
}
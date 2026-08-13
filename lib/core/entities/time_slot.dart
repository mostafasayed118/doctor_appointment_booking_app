import 'package:equatable/equatable.dart';

/// A single bookable time window for a doctor.
///
/// Each slot is its own Firestore document (`slots/<slotId>`), which is what
/// lets a booking transaction atomically flip `isBooked` on exactly one
/// document — no write hotspot on a shared "day schedule" doc.
///
/// Times are stored as UTC instants (from Firestore `Timestamp`s) and mapped
/// to device-local time in the UI. Comparisons for "is this slot in the
/// past" use the device clock — see [SlotPolicy].
class TimeSlot extends Equatable {
  const TimeSlot({
    required this.id,
    required this.doctorId,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });

  final String id;
  final String doctorId;

  /// Start of the slot as a UTC instant.
  final DateTime startTime;

  /// End of the slot as a UTC instant.
  final DateTime endTime;
  final bool isBooked;

  @override
  List<Object?> get props => [id, doctorId, startTime, endTime, isBooked];
}
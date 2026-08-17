import 'package:equatable/equatable.dart';

import '../../../core/entities/time_slot.dart';
import '../../../core/error/app_error.dart';
import 'slot_grouping.dart';

/// All the states the slot selection screen can be in.
///
/// Sealed so the compiler knows every variant — exhaustive `switch`
/// matching is enforced, and no new state can be invented outside this file.
sealed class SlotSelectionState extends Equatable {
  const SlotSelectionState();

  @override
  List<Object?> get props => [];
}

/// Nothing has happened yet.
final class SlotSelectionInitial extends SlotSelectionState {
  const SlotSelectionInitial();
}

/// The slots are being loaded.
final class SlotSelectionLoading extends SlotSelectionState {
  const SlotSelectionLoading();
}

/// Slots are loaded and grouped into days. [selectedDayIndex] points into
/// [days]; [selectedSlot] is the tile the patient tapped (null until one
/// is chosen) — Task 12's confirm flow consumes it.
final class SlotSelectionLoaded extends SlotSelectionState {
  const SlotSelectionLoaded({
    required this.doctorId,
    required this.days,
    this.selectedDayIndex = 0,
    this.selectedSlot,
  });

  final String doctorId;
  final List<SlotDay> days;
  final int selectedDayIndex;
  final TimeSlot? selectedSlot;

  SlotDay get selectedDay => days[selectedDayIndex];

  @override
  List<Object?> get props =>
      [doctorId, days, selectedDayIndex, selectedSlot];
}

/// The load failed.
final class SlotSelectionError extends SlotSelectionState {
  const SlotSelectionError(this.error);

  final AppError error;

  @override
  List<Object?> get props => [error];
}

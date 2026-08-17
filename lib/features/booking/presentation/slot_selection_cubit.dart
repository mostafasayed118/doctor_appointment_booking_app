import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/time_slot.dart';
import '../../../core/error/result.dart';
import '../domain/use_cases/get_slots.dart';
import 'slot_grouping.dart';
import 'slot_selection_state.dart';

/// Owns the slot selection screen: loads a doctor's slots, groups them
/// into days (pure [groupSlotsByDay]), and tracks the selected day + tile.
///
/// [now] is injectable so past-slot filtering is deterministic in tests;
/// production uses the device clock.
class SlotSelectionCubit extends Cubit<SlotSelectionState> {
  SlotSelectionCubit({
    required this._getSlots,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const SlotSelectionInitial());

  final GetSlots _getSlots;
  final DateTime Function() _now;

  String? _lastDoctorId;

  Future<void> load(String doctorId) async {
    _lastDoctorId = doctorId;
    emit(const SlotSelectionLoading());
    final result = await _getSlots(doctorId);
    switch (result) {
      case Success(:final value):
        emit(SlotSelectionLoaded(
          doctorId: doctorId,
          days: groupSlotsByDay(value, now: _now()),
        ));
      case Failure(:final error):
        emit(SlotSelectionError(error));
    }
  }

  void retry() {
    final id = _lastDoctorId;
    if (id != null) load(id);
  }

  /// Switches the visible day. A selected slot belongs to a specific day,
  /// so the selection is cleared on the switch.
  void selectDay(int index) {
    final current = state;
    if (current is! SlotSelectionLoaded) return;
    if (index < 0 || index >= current.days.length) return;
    emit(SlotSelectionLoaded(
      doctorId: current.doctorId,
      days: current.days,
      selectedDayIndex: index,
    ));
  }

  void selectSlot(TimeSlot slot) {
    final current = state;
    if (current is! SlotSelectionLoaded) return;
    emit(SlotSelectionLoaded(
      doctorId: current.doctorId,
      days: current.days,
      selectedDayIndex: current.selectedDayIndex,
      selectedSlot: slot,
    ));
  }

  /// Toggles the selection off when the tapped tile is already selected.
  void clearSelection() {
    final current = state;
    if (current is! SlotSelectionLoaded) return;
    emit(SlotSelectionLoaded(
      doctorId: current.doctorId,
      days: current.days,
      selectedDayIndex: current.selectedDayIndex,
    ));
  }
}

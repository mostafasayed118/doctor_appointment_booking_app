import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entities/appointment.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/app_error_view.dart';
import '../../../shared/components/constrained_content.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/language_toggle_button.dart';
import '../../../shared/components/loading_view.dart';
import 'slot_selection_cubit.dart';
import 'slot_selection_state.dart';
import 'widgets/day_selector.dart';
import 'widgets/slot_tile.dart';

/// The booking screen: pick a day, then a time.
///
/// Reached at `/doctors/:id/book`; the router supplies the
/// [SlotSelectionCubit] (already loading) above this page. Selection state
/// lives in the cubit — Task 12's confirm flow consumes `selectedSlot`.
class SlotSelectionPage extends StatelessWidget {
  const SlotSelectionPage({super.key, this.doctorName, this.reschedule});

  /// The doctor's name, passed via router `extra` from the profile page so
  /// the AppBar can show who is being booked (deep-link restores fall back
  /// to the generic localized title — `extra` isn't preserved across them).
  final String? doctorName;

  /// Non-null in reschedule mode (Task 14): the appointment being moved.
  /// Drives the AppBar title, the confirm button label, and the confirm
  /// route's `extra` — a `(Appointment, TimeSlot)` record instead of a bare
  /// [TimeSlot], so the reschedule transaction knows WHICH appointment to
  /// move and which slot it is moving to.
  final Appointment? reschedule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          doctorName ??
              (reschedule != null
                  ? l10n.rescheduleAppointmentTitle
                  : l10n.bookAppointment),
        ),
        actions: const [LanguageToggleButton()],
      ),
      body: BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
        builder: (context, state) {
          final cubit = context.read<SlotSelectionCubit>();
          return switch (state) {
            SlotSelectionInitial() ||
            SlotSelectionLoading() => const LoadingView(),
            SlotSelectionError(:final error) => AppErrorView(
              error: error,
              onRetry: cubit.retry,
            ),
            SlotSelectionLoaded() => _buildContent(context, l10n, state),
          };
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    SlotSelectionLoaded state,
  ) {
    final cubit = context.read<SlotSelectionCubit>();
    // No slot documents at all for this doctor — nothing to pick from.
    if (state.days.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        title: l10n.noSlotsAvailable,
        subtitle: l10n.noSlotsAvailableSubtitle,
      );
    }
    final selectedDay = state.selectedDay;
    return ConstrainedContent(
      // Capping the width keeps tiles a sane size on tablet/desktop; the
      // grid below adapts its column count to whatever width it gets.
      maxWidth: 900,
      child: Column(
        children: [
          DaySelector(
            days: state.days,
            selectedIndex: state.selectedDayIndex,
            onSelected: cubit.selectDay,
          ),
          Expanded(
            child: selectedDay.hasSlots
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    // Auto-computed columns (~130dp tiles): ~3 on a phone,
                    // more on tablet/desktop — no hard-coded breakpoints.
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 130,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 2.2,
                        ),
                    itemCount: selectedDay.slots.length,
                    itemBuilder: (context, index) {
                      final slot = selectedDay.slots[index];
                      return SlotTile(
                        slot: slot,
                        selected: state.selectedSlot?.id == slot.id,
                        onTap: () => cubit.selectSlot(slot),
                      );
                    },
                  )
                : EmptyState(
                    icon: Icons.event_busy,
                    title: l10n.noSlotsThisDay,
                    subtitle: l10n.noSlotsThisDaySubtitle,
                  ),
          ),
          // Confirm is only possible once a tile is selected; the slot rides
          // along as router `extra` so the confirmation route doesn't need a
          // second fetch (deep-link restores of /confirm have no extra and
          // bounce back here).
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: state.selectedSlot == null
                ? const SizedBox.shrink()
                : AppButton(
                    label: reschedule != null
                        ? l10n.rescheduleAppointment
                        : l10n.confirmBooking,
                    icon: Icons.check,
                    // Explicit absolute targets: a relative push('confirm')
                    // does NOT resolve to these nested routes in GoRouter
                    // (it ends up unmatchable — caught by the responsive
                    // widget tests), so each mode names its own confirm route;
                    // only the extra shape differs.
                    onPressed: () => reschedule != null
                        ? context.push(
                            '/appointments/reschedule/confirm',
                            extra: (reschedule!, state.selectedSlot),
                          )
                        : context.push(
                            '/doctors/${state.doctorId}/book/confirm',
                            extra: state.selectedSlot,
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

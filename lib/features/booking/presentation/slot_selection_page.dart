import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_error_view.dart';
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
  const SlotSelectionPage({super.key, this.doctorName});

  /// The doctor's name, passed via router `extra` from the profile page so
  /// the AppBar can show who is being booked (deep-link restores fall back
  /// to the generic localized title — `extra` isn't preserved across them).
  final String? doctorName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(doctorName ?? l10n.bookAppointment),
        actions: const [LanguageToggleButton()],
      ),
      body: BlocBuilder<SlotSelectionCubit, SlotSelectionState>(
        builder: (context, state) {
          final cubit = context.read<SlotSelectionCubit>();
          return switch (state) {
            SlotSelectionInitial() || SlotSelectionLoading() =>
              const LoadingView(),
            SlotSelectionError(:final error) =>
              AppErrorView(error: error, onRetry: cubit.retry),
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
    return Column(
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
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
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
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/entities/time_slot.dart';

/// One tappable time tile in the booking screen.
///
/// Shows the slot's start time in the device's local timezone, formatted
/// with the ambient [Locale]. Selected tiles get the primary-container
/// highlight so the patient can see what Task 12 will confirm.
class SlotTile extends StatelessWidget {
  const SlotTile({
    super.key,
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final TimeSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          child: Text(
            DateFormat.Hm(locale.toLanguageTag())
                .format(slot.startTime.toLocal()),
            style: theme.textTheme.titleMedium?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

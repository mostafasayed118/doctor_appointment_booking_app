import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../slot_grouping.dart';

/// Horizontal strip of day chips — one per [SlotDay]. The selected day is
/// highlighted; tapping another day switches the visible slot list.
///
/// Labels are localized via `intl` using the ambient [Locale]: weekday
/// abbreviation on top, day-of-month below.
class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.days,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<SlotDay> days;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = index == selectedIndex;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => onSelected(index),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.E(locale.toLanguageTag()).format(day.day),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  DateFormat.d(locale.toLanguageTag()).format(day.day),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

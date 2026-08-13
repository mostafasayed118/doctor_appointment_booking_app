import 'package:flutter/material.dart';

/// Horizontal specialty filter: an "All" chip plus one chip per distinct
/// specialty in the loaded list. Tapping a specialty selects it; tapping
/// "All" (or the selected chip's own toggle) clears the filter.
class SpecialtyFilterBar extends StatelessWidget {
  const SpecialtyFilterBar({
    super.key,
    required this.specialties,
    required this.selected,
    required this.onSelected,
    required this.allLabel,
  });

  final List<String> specialties;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final String allLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: specialties.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final specialty = isAll ? null : specialties[index - 1];
          return FilterChip(
            label: Text(isAll ? allLabel : specialty!),
            selected: selected == specialty,
            onSelected: (_) => onSelected(specialty),
          );
        },
      ),
    );
  }
}

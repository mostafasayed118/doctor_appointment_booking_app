import 'package:flutter/material.dart';

import '../../../../core/entities/appointment.dart';
import '../../../../l10n/app_localizations.dart';

/// A small colored chip showing an appointment's lifecycle status.
///
/// Pure rendering: the label comes from l10n, the colors from the theme
/// scheme, and the meaning from the [AppointmentStatus] enum.
class AppointmentStatusBadge extends StatelessWidget {
  const AppointmentStatusBadge({super.key, required this.status});

  final AppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (label, background, foreground) = switch (status) {
      AppointmentStatus.scheduled => (
          l10n.statusScheduled,
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
        ),
      AppointmentStatus.cancelled => (
          l10n.statusCancelled,
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
        ),
      AppointmentStatus.completed => (
          l10n.statusCompleted,
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

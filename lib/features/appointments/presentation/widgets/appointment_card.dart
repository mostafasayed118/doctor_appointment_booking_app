import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/entities/appointment.dart';
import '../../../../core/entities/doctor.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../doctors/presentation/widgets/doctor_photo.dart';
import 'appointment_status_badge.dart';

/// One row in the appointments list: doctor photo/name/specialty, the
/// appointment's date + time range, a status badge, and — for cancellable
/// (upcoming) appointments — a cancel button.
///
/// [doctor] is nullable because the appointment doc stores only `doctorId`:
/// a doctor missing from the lookup map (data inconsistency) renders a
/// placeholder avatar + label instead of crashing the list.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.doctor,
    this.onCancel,
    this.onReschedule,
    this.cancelling = false,
  });

  final Appointment appointment;

  /// The doctor for [appointment.doctorId], when the lookup found it.
  final Doctor? doctor;

  /// Called when the patient taps Cancel (after the confirmation dialog —
  /// the dialog lives in the page). Null hides the button, e.g. for
  /// appointments that can't be cancelled.
  final VoidCallback? onCancel;

  /// Called when the patient taps Reschedule (Task 14) — the page pushes
  /// the slot-selection screen in reschedule mode. Null hides the button.
  final VoidCallback? onReschedule;

  /// True while this appointment's cancel transaction is in flight — shows
  /// a spinner instead of the button so a double-tap can't fire twice.
  final bool cancelling;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Display in device-local time (the entity carries UTC instants).
    final start = appointment.startTime.toLocal();
    final date = DateFormat.yMMMMEEEEd(locale).format(start);
    final timeRange =
        '${DateFormat.Hm(locale).format(start)} – '
        '${DateFormat.Hm(locale).format(appointment.endTime.toLocal())}';
    final doctorName = doctor?.name ?? l10n.unknownDoctor;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        // Two rows instead of one wide row: the header (photo, content,
        // badge) on top, the actions BELOW it at full card width — so the
        // buttons wrap naturally on narrow phones instead of squeezing the
        // content or overflowing the row.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doctor != null)
                  DoctorPhoto(doctor: doctor!, radius: 28)
                else
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    child: const Icon(Icons.person_outline),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctorName, style: theme.textTheme.titleMedium),
                      if (doctor != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          doctor!.specialty,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(date, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      Text(
                        timeRange,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AppointmentStatusBadge(status: appointment.status),
              ],
            ),
            if (onCancel != null || onReschedule != null) ...[
              const SizedBox(height: 8),
              if (cancelling)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                // Full card width, so on narrow phones the two buttons fold
                // to a second line rather than overflowing.
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (onReschedule != null)
                      TextButton(
                        onPressed: onReschedule,
                        child: Text(l10n.rescheduleAppointment),
                      ),
                    if (onCancel != null)
                      OutlinedButton(
                        onPressed: onCancel,
                        child: Text(l10n.cancelAppointment),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

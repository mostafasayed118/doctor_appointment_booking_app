import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/entities/appointment.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/app_error_view.dart';
import '../../../shared/components/loading_view.dart';
import 'booking_cubit.dart';
import 'booking_state.dart';

/// Shows the outcome of a booking attempt.
///
/// The route provides a [BookingCubit] that has already started [BookingCubit.confirm];
/// this page is a pure renderer of the resulting state:
/// - in flight → [LoadingView]
/// - confirmed → success view with the appointment time
/// - error → [AppErrorView]; retry re-runs the confirm (right for network
///   failures), the AppBar back returns to slot selection (right for
///   "slot no longer available").
class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<BookingCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.bookAppointment)),
      body: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) => switch (state) {
          BookingInitial() || BookingConfirming() => const LoadingView(),
          BookingError(:final error) => AppErrorView(
            error: error,
            onRetry: cubit.retry,
          ),
          BookingConfirmed(:final appointment) => _SuccessView(
            appointment: appointment,
          ),
          BookingRescheduled(:final appointment) => _SuccessView(
            appointment: appointment,
            rescheduled: true,
          ),
        },
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.appointment, this.rescheduled = false});

  final Appointment appointment;

  /// True after a reschedule (Task 14): the heading and the exit button
  /// point at the appointments list instead of the doctors list.
  final bool rescheduled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    // Display in device-local time (the entity carries UTC instants).
    final start = appointment.startTime.toLocal();
    final date = DateFormat.yMMMMEEEEd(locale.toLanguageTag()).format(start);
    final time = DateFormat.Hm(locale.toLanguageTag()).format(start);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle, size: 96, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            rescheduled ? l10n.rescheduleConfirmedTitle : l10n.bookingConfirmedTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text(
            date,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            time,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          AppButton(
            label: rescheduled ? l10n.backToAppointments : l10n.backToDoctors,
            onPressed: () => context.go(rescheduled ? '/appointments' : '/doctors'),
          ),
        ],
      ),
    );
  }
}

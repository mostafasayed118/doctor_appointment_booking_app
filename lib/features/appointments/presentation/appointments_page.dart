import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entities/appointment.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_error_view.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/language_toggle_button.dart';
import '../../../shared/components/loading_view.dart';
import 'appointments_cubit.dart';
import 'appointments_state.dart';
import 'widgets/appointment_card.dart';

/// The patient's appointments screen: an Upcoming / Past tab pair, each
/// listing [AppointmentCard]s, with a cancel flow on upcoming ones.
///
/// Reached at `/appointments`; the router supplies the
/// [AppointmentsCubit] (already loading) above this page.
class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appointmentsTitle),
        actions: const [LanguageToggleButton()],
      ),
      body: BlocBuilder<AppointmentsCubit, AppointmentsState>(
        builder: (context, state) {
          final cubit = context.read<AppointmentsCubit>();
          return switch (state) {
            AppointmentsInitial() || AppointmentsLoading() =>
              const LoadingView(),
            AppointmentsError(:final error) => AppErrorView(
              error: error,
              onRetry: cubit.retry,
            ),
            AppointmentsLoaded() =>
              _buildContent(context, l10n, state, cubit),
          };
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    AppointmentsLoaded state,
    AppointmentsCubit cubit,
  ) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [Tab(text: l10n.upcomingTab), Tab(text: l10n.pastTab)],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(context, l10n, state, cubit, upcoming: true),
                _buildList(context, l10n, state, cubit, upcoming: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    AppLocalizations l10n,
    AppointmentsLoaded state,
    AppointmentsCubit cubit, {
    required bool upcoming,
  }) {
    final appointments = upcoming ? state.upcoming : state.past;
    if (appointments.isEmpty) {
      return EmptyState(
        icon: upcoming ? Icons.event_available : Icons.history,
        title: upcoming ? l10n.noUpcomingAppointments : l10n.noPastAppointments,
        subtitle: upcoming
            ? l10n.noUpcomingAppointmentsSubtitle
            : l10n.noPastAppointmentsSubtitle,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return AppointmentCard(
          appointment: appointment,
          doctor: state.doctorsById[appointment.doctorId],
          cancelling: state.cancellingId == appointment.id,
          // Only still-scheduled appointments (which is exactly the
          // upcoming list) can be cancelled or rescheduled.
          onCancel: upcoming
              ? () => _confirmCancel(context, cubit, appointment)
              : null,
          onReschedule: upcoming
              ? () => _startReschedule(context, appointment)
              : null,
        );
      },
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    AppointmentsCubit cubit,
    Appointment appointment,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cancelAppointmentTitle),
        content: Text(l10n.cancelAppointmentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelDismiss),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.cancelConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      cubit.cancel(appointment.id);
    }
  }

  /// Opens slot selection in reschedule mode (Task 14); the appointment
  /// rides along as `extra` so the route knows which appointment to move
  /// and which slot to exclude. No dialog — the reschedule confirm screen
  /// is the confirmation moment.
  void _startReschedule(BuildContext context, Appointment appointment) {
    context.push('/appointments/reschedule', extra: appointment);
  }
}

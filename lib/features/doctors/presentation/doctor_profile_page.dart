import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/entities/doctor.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/app_error_view.dart';
import '../../../shared/components/constrained_content.dart';
import '../../../shared/components/language_toggle_button.dart';
import '../../../shared/components/loading_view.dart';
import 'doctor_profile_cubit.dart';
import 'doctors_state.dart';
import 'widgets/doctor_photo.dart';

/// A single doctor's full profile, reached at `/doctors/:id`. The router
/// supplies the [DoctorProfileCubit] (which already started loading) above
/// this page. Booking entry lands here in Task 11.
class DoctorProfilePage extends StatelessWidget {
  const DoctorProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorProfile),
        actions: const [LanguageToggleButton()],
      ),
      body: BlocBuilder<DoctorProfileCubit, DoctorProfileState>(
        builder: (context, state) {
          final cubit = context.read<DoctorProfileCubit>();
          return switch (state) {
            DoctorProfileInitial() ||
            DoctorProfileLoading() => const LoadingView(),
            DoctorProfileError(:final error) => AppErrorView(
              error: error,
              onRetry: cubit.retry,
            ),
            DoctorProfileLoaded(:final doctor) => _ProfileBody(
              doctor: doctor,
              bioTitle: l10n.profileBio,
              clinicTitle: l10n.profileClinic,
              bookLabel: l10n.bookAppointment,
            ),
          };
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.doctor,
    required this.bioTitle,
    required this.clinicTitle,
    required this.bookLabel,
  });

  final Doctor doctor;
  final String bioTitle;
  final String clinicTitle;
  final String bookLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedContent(
      // The profile reads best as a centered ~800-wide column; capping it
      // keeps the bio/clinic cards from stretching edge-to-edge on desktop.
      maxWidth: 800,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(child: DoctorPhoto(doctor: doctor, radius: 48)),
          const SizedBox(height: 16),
          Text(
            doctor.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            doctor.specialty,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, size: 18, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  doctor.rating.toStringAsFixed(1),
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _InfoSection(
            title: bioTitle,
            child: Text(doctor.bio, style: theme.textTheme.bodyMedium),
          ),
          const SizedBox(height: 16),
          _InfoSection(
            title: clinicTitle,
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(doctor.clinicAddress)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Booking entry: pass the Doctor via `extra` so the booking screen
          // can show the name without a second fetch; the id travels in the
          // path so deep-link restores still work.
          AppButton(
            label: bookLabel,
            icon: Icons.calendar_month_outlined,
            onPressed: () =>
                context.push('/doctors/${doctor.id}/book', extra: doctor),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

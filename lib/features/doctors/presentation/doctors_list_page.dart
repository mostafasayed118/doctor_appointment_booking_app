import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_error_view.dart';
import '../../../shared/components/app_text_field.dart';
import '../../../shared/components/empty_state.dart';
import '../../../shared/components/language_toggle_button.dart';
import '../../../shared/components/loading_view.dart';
import 'doctor_filters.dart';
import 'doctors_state.dart';
import 'doctors_list_cubit.dart';
import 'widgets/doctor_card.dart';
import 'widgets/specialty_filter_bar.dart';

/// The doctors browse screen: search field, specialty filter bar, and the
/// list of matching [DoctorCard]s. Reached via the router at `/doctors`;
/// the router supplies the [DoctorsListCubit] above this page.
class DoctorsListPage extends StatefulWidget {
  const DoctorsListPage({super.key});

  @override
  State<DoctorsListPage> createState() => _DoctorsListPageState();
}

class _DoctorsListPageState extends State<DoctorsListPage> {
  // The search field's text lives here (single source for the input); the
  // cubit mirrors it in state for filtering and tests.
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorsTitle),
        actions: [
          const LanguageToggleButton(),
          // Dev-only: the component gallery is no longer the landing, so
          // keep it one tap away (theme/locale toggles, sign-out).
          IconButton(
            icon: const Icon(Icons.widgets_outlined),
            tooltip: 'Dev gallery',
            onPressed: () => context.push('/home'),
          ),
        ],
      ),
      body: BlocBuilder<DoctorsListCubit, DoctorsState>(
        builder: (context, state) {
          final cubit = context.read<DoctorsListCubit>();
          return switch (state) {
            DoctorsInitial() || DoctorsLoading() => const LoadingView(),
            DoctorsError(:final error) =>
              AppErrorView(error: error, onRetry: cubit.load),
            DoctorsLoaded() => _buildContent(context, l10n, state),
          };
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    DoctorsLoaded state,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: AppTextField(
            controller: _searchController,
            label: l10n.searchDoctors,
            prefixIcon: Icons.search,
            onChanged: context.read<DoctorsListCubit>().search,
          ),
        ),
        SpecialtyFilterBar(
          specialties: distinctSpecialties(state.allDoctors),
          selected: state.selectedSpecialty,
          allLabel: l10n.allSpecialties,
          onSelected: context.read<DoctorsListCubit>().filterBySpecialty,
        ),
        Expanded(
          child: state.filteredDoctors.isEmpty
              ? EmptyState(
                  icon: state.isFiltering
                      ? Icons.search_off
                      : Icons.medical_services_outlined,
                  title: state.isFiltering ? l10n.noMatches : l10n.noDoctors,
                  subtitle:
                      state.isFiltering ? l10n.noMatchesSubtitle : l10n.noDoctorsSubtitle,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.filteredDoctors.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doctor = state.filteredDoctors[index];
                    return DoctorCard(
                      doctor: doctor,
                      onTap: () => context.push('/doctors/${doctor.id}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../domain/use_cases/get_doctors.dart';
import 'doctor_filters.dart';
import 'doctors_state.dart';

/// Owns the doctors browse list.
///
/// Loads once from the repository, then search/filter re-derive
/// [DoctorsLoaded.filteredDoctors] client-side from the already-loaded list
/// — the dataset is small (tens of doctors), so no Firestore round-trips
/// per keystroke and no composite indexes.
class DoctorsListCubit extends Cubit<DoctorsState> {
  DoctorsListCubit({required this._getDoctors}) : super(const DoctorsInitial());

  final GetDoctors _getDoctors;

  Future<void> load() async {
    emit(const DoctorsLoading());
    final result = await _getDoctors();
    switch (result) {
      case Success(:final value):
        emit(DoctorsLoaded(
          allDoctors: value,
          filteredDoctors: filterDoctors(value),
        ));
      case Failure(:final error):
        emit(DoctorsError(error));
    }
  }

  void search(String query) => _refilter(query, _currentSpecialty);

  /// null clears the specialty filter.
  void filterBySpecialty(String? specialty) => _refilter(_currentQuery, specialty);

  String get _currentQuery =>
      state is DoctorsLoaded ? (state as DoctorsLoaded).query : '';

  String? get _currentSpecialty =>
      state is DoctorsLoaded ? (state as DoctorsLoaded).selectedSpecialty : null;

  void _refilter(String query, String? specialty) {
    final current = state;
    if (current is! DoctorsLoaded) return; // nothing loaded yet — ignore
    emit(DoctorsLoaded(
      allDoctors: current.allDoctors,
      filteredDoctors: filterDoctors(current.allDoctors,
          query: query, specialty: specialty),
      query: query,
      selectedSpecialty: specialty,
    ));
  }
}

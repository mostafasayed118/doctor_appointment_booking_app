import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/result.dart';
import '../domain/use_cases/get_doctor.dart';
import 'doctors_state.dart';

/// Owns a single doctor's profile screen state.
class DoctorProfileCubit extends Cubit<DoctorProfileState> {
  DoctorProfileCubit({required this._getDoctor})
      : super(const DoctorProfileInitial());

  final GetDoctor _getDoctor;

  /// Last requested id — lets [retry] reload after an error without the
  /// page needing to know it.
  String? _lastId;

  Future<void> load(String id) async {
    _lastId = id;
    emit(const DoctorProfileLoading());
    final result = await _getDoctor(id);
    switch (result) {
      case Success(:final value):
        emit(DoctorProfileLoaded(value));
      case Failure(:final error):
        emit(DoctorProfileError(error));
    }
  }

  void retry() {
    final id = _lastId;
    if (id != null) load(id);
  }
}

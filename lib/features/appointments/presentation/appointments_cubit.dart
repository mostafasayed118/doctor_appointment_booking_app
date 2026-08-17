import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/appointment.dart';
import '../../../core/entities/doctor.dart';
import '../../../core/error/result.dart';
import '../../doctors/domain/use_cases/get_doctors.dart';
import '../domain/use_cases/cancel_appointment.dart';
import '../domain/use_cases/get_appointments.dart';
import 'appointments_state.dart';

/// Owns the appointments screen: loads the patient's appointments + the
/// doctors list (for name/photo lookup), splits into upcoming/past, and
/// runs cancels.
///
/// [now] is injectable so the upcoming/past boundary is deterministic in
/// tests; production uses the device clock. The split rule: an appointment
/// is upcoming iff it is still scheduled AND its start time is in the
/// future — everything else (cancelled, completed, started) is past.
class AppointmentsCubit extends Cubit<AppointmentsState> {
  AppointmentsCubit({
    required this._getAppointments,
    required this._cancelAppointment,
    required this._getDoctors,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(const AppointmentsInitial());

  final GetAppointments _getAppointments;
  final CancelAppointment _cancelAppointment;
  final GetDoctors _getDoctors;
  final DateTime Function() _now;

  String? _lastPatientId;

  /// Cached doctor lookup; refreshed on every full [load]. Cancel reloads
  /// reuse it — no second doctors fetch per cancel.
  Map<String, Doctor>? _doctorsById;

  Future<void> load(String patientId) async {
    _lastPatientId = patientId;
    emit(const AppointmentsLoading());
    final result = await _getAppointments(patientId);
    switch (result) {
      case Success(:final value):
        final doctorsResult = await _getDoctors();
        switch (doctorsResult) {
          case Success(value: final doctors):
            _doctorsById = {for (final doctor in doctors) doctor.id: doctor};
            emit(_buildLoaded(value));
          case Failure(:final error):
            emit(AppointmentsError(error));
        }
      case Failure(:final error):
        emit(AppointmentsError(error));
    }
  }

  void retry() {
    final patientId = _lastPatientId;
    if (patientId != null) load(patientId);
  }

  /// Cancels [appointmentId], then re-reads the appointments so the list
  /// reflects the authoritative Firestore state (cancel → moves to past,
  /// slot freed). A cancel already in flight is ignored — the [cancellingId]
  /// guard makes double-taps a no-op.
  Future<void> cancel(String appointmentId) async {
    final patientId = _lastPatientId;
    final current = state;
    if (patientId == null || current is! AppointmentsLoaded) return;
    if (current.cancellingId != null) return;

    emit(AppointmentsLoaded(
      upcoming: current.upcoming,
      past: current.past,
      doctorsById: current.doctorsById,
      cancellingId: appointmentId,
    ));
    final result = await _cancelAppointment(
      patientId: patientId,
      appointmentId: appointmentId,
    );
    switch (result) {
      case Success():
        await _reloadAppointments(patientId);
      case Failure(:final error):
        emit(AppointmentsError(error));
    }
  }

  Future<void> _reloadAppointments(String patientId) async {
    final result = await _getAppointments(patientId);
    switch (result) {
      case Success(:final value):
        emit(_buildLoaded(value));
      case Failure(:final error):
        emit(AppointmentsError(error));
    }
  }

  AppointmentsLoaded _buildLoaded(List<Appointment> appointments) {
    final now = _now();
    final upcoming = <Appointment>[];
    final past = <Appointment>[];
    for (final appointment in appointments) {
      final isUpcoming = appointment.status == AppointmentStatus.scheduled &&
          appointment.startTime.isAfter(now);
      (isUpcoming ? upcoming : past).add(appointment);
    }
    return AppointmentsLoaded(
      upcoming: upcoming,
      past: past,
      // Appointments are sorted by startTime upstream, so both lists stay
      // chronologically ordered. A doctor doc missing from the lookup is a
      // data inconsistency the card renders with a placeholder.
      doctorsById: Map<String, Doctor>.from(_doctorsById ?? const {}),
    );
  }
}

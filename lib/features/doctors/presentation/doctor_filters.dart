import '../../../core/entities/doctor.dart';

/// Client-side search/filter over an already-loaded doctor list.
///
/// Search is a case-insensitive substring match on name OR specialty;
/// [specialty] is an exact single-select filter. Both compose. Pure Dart
/// so the filtering rules are unit-testable without any state machine.
List<Doctor> filterDoctors(
  List<Doctor> doctors, {
  String query = '',
  String? specialty,
}) {
  final q = query.trim().toLowerCase();
  return doctors.where((doctor) {
    final matchesSpecialty =
        specialty == null || doctor.specialty == specialty;
    final matchesQuery = q.isEmpty ||
        doctor.name.toLowerCase().contains(q) ||
        doctor.specialty.toLowerCase().contains(q);
    return matchesSpecialty && matchesQuery;
  }).toList();
}

/// Distinct specialties of [doctors], alphabetically sorted — feeds the
/// filter bar (self-maintaining, no hardcoded specialty list).
List<String> distinctSpecialties(List<Doctor> doctors) =>
    doctors.map((d) => d.specialty).toSet().toList()..sort();

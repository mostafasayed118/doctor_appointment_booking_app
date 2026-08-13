import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/doctor_filters.dart';

Doctor doc(String id, String name, String specialty) => Doctor(
      id: id,
      name: name,
      specialty: specialty,
      bio: 'Bio $id',
      rating: 4.5,
      clinicAddress: 'Clinic $id',
      photoUrl: '',
    );

void main() {
  final ana = doc('d1', 'Ana Patel', 'Cardiology');
  final omar = doc('d2', 'Omar Haddad', 'Dermatology');
  final leila = doc('d3', 'Leila Hassan', 'Cardiology');
  final all = [ana, omar, leila];

  group('filterDoctors', () {
    test('returns everything with no query or specialty', () {
      expect(filterDoctors(all), all);
    });

    test('matches the name, case-insensitively', () {
      expect(filterDoctors(all, query: 'ANA'), [ana]);
      expect(filterDoctors(all, query: 'hassan'), [leila]);
    });

    test('also matches the specialty term', () {
      expect(filterDoctors(all, query: 'cardio'), [ana, leila]);
    });

    test('trims surrounding whitespace', () {
      expect(filterDoctors(all, query: '  ana  '), [ana]);
    });

    test('filters by exact specialty', () {
      expect(filterDoctors(all, specialty: 'Cardiology'), [ana, leila]);
    });

    test('composes specialty + query', () {
      expect(
        filterDoctors(all, query: 'leila', specialty: 'Cardiology'),
        [leila],
      );
      // The query must match within the selected specialty.
      expect(
        filterDoctors(all, query: 'leila', specialty: 'Dermatology'),
        isEmpty,
      );
    });
  });

  group('distinctSpecialties', () {
    test('deduplicates and sorts alphabetically', () {
      expect(distinctSpecialties(all), ['Cardiology', 'Dermatology']);
    });

    test('is empty for an empty list', () {
      expect(distinctSpecialties(const []), isEmpty);
    });
  });
}

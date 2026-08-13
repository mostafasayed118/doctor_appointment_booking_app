import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/data/error/firebase_error_mapper.dart';
import 'package:doctor_appointment_booking_app/features/doctors/data/doctors_repository_impl.dart';
import 'package:doctor_appointment_booking_app/features/doctors/data/firestore_doctors_data_source.dart';

class MockDoctorsDataSource extends Mock implements FirestoreDoctorsDataSource {}

void main() {
  const doctor = Doctor(
    id: 'd1',
    name: 'Ana Patel',
    specialty: 'Cardiology',
    bio: 'Bio',
    rating: 4.8,
    clinicAddress: 'Clinic',
    photoUrl: '',
  );

  late MockDoctorsDataSource dataSource;
  late DoctorsRepositoryImpl repository;

  setUp(() {
    dataSource = MockDoctorsDataSource();
    repository = DoctorsRepositoryImpl(
      dataSource: dataSource,
      mapper: const FirebaseErrorMapper(),
    );
  });

  group('getDoctors', () {
    test('returns Success with the doctors', () async {
      when(() => dataSource.fetchDoctors())
          .thenAnswer((_) async => const [doctor]);

      final result = await repository.getDoctors();

      expect(result, isA<Success<List<Doctor>>>());
      expect((result as Success<List<Doctor>>).value, const [doctor]);
    });

    test('maps a Firestore network error to Failure<NetworkError>', () async {
      when(() => dataSource.fetchDoctors()).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      final result = await repository.getDoctors();

      expect((result as Failure<List<Doctor>>).error, isA<NetworkError>());
    });

    test('maps unexpected errors to Failure<UnexpectedError>', () async {
      when(() => dataSource.fetchDoctors()).thenThrow(StateError('boom'));

      final result = await repository.getDoctors();

      expect((result as Failure<List<Doctor>>).error, isA<UnexpectedError>());
    });
  });

  group('getDoctor', () {
    test('returns Success with the doctor', () async {
      when(() => dataSource.fetchDoctor('d1'))
          .thenAnswer((_) async => doctor);

      final result = await repository.getDoctor('d1');

      expect(result, isA<Success<Doctor>>());
      expect((result as Success<Doctor>).value, doctor);
    });

    test('maps a missing doctor to Failure<NotFoundError>', () async {
      when(() => dataSource.fetchDoctor('nope')).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Doctor nope was not found.',
        ),
      );

      final result = await repository.getDoctor('nope');

      expect((result as Failure<Doctor>).error, isA<NotFoundError>());
    });
  });
}

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart' as core;
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/doctors_repository.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/use_cases/get_doctor.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/doctor_profile_cubit.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/doctors_state.dart';

class MockDoctorsRepository extends Mock implements DoctorsRepository {}

void main() {
  const doctor = Doctor(
    id: 'd1',
    name: 'Ana Patel',
    specialty: 'Cardiology',
    bio: 'Cardiologist with 15 years of experience.',
    rating: 4.8,
    clinicAddress: '12 Medical Ave',
    photoUrl: '',
  );

  late MockDoctorsRepository repository;

  setUp(() {
    repository = MockDoctorsRepository();
  });

  DoctorProfileCubit buildCubit() =>
      DoctorProfileCubit(getDoctor: GetDoctor(repository));

  group('load', () {
    blocTest<DoctorProfileCubit, DoctorProfileState>(
      'emits Loading then Loaded',
      build: buildCubit,
      setUp: () => when(() => repository.getDoctor('d1'))
          .thenAnswer((_) async => const Success(doctor)),
      act: (cubit) => cubit.load('d1'),
      expect: () => const [
        DoctorProfileLoading(),
        DoctorProfileLoaded(doctor),
      ],
    );

    blocTest<DoctorProfileCubit, DoctorProfileState>(
      'emits Error with NotFoundError for a missing doctor',
      build: buildCubit,
      setUp: () => when(() => repository.getDoctor('nope'))
          .thenAnswer((_) async => const Failure(core.NotFoundError())),
      act: (cubit) => cubit.load('nope'),
      expect: () => const [
        DoctorProfileLoading(),
        DoctorProfileError(core.NotFoundError()),
      ],
    );

    blocTest<DoctorProfileCubit, DoctorProfileState>(
      'emits Error on failure',
      build: buildCubit,
      setUp: () => when(() => repository.getDoctor('d1'))
          .thenAnswer((_) async => const Failure(core.NetworkError())),
      act: (cubit) => cubit.load('d1'),
      expect: () => const [
        DoctorProfileLoading(),
        DoctorProfileError(core.NetworkError()),
      ],
    );

    blocTest<DoctorProfileCubit, DoctorProfileState>(
      'retry reloads the same doctor after an error',
      build: buildCubit,
      setUp: () {
        when(() => repository.getDoctor('d1'))
            .thenAnswer((_) async => const Failure(core.NetworkError()));
      },
      act: (cubit) async {
        await cubit.load('d1');
        when(() => repository.getDoctor('d1'))
            .thenAnswer((_) async => const Success(doctor));
        cubit.retry();
      },
      expect: () => const [
        DoctorProfileLoading(),
        DoctorProfileError(core.NetworkError()),
        DoctorProfileLoading(),
        DoctorProfileLoaded(doctor),
      ],
    );
  });
}

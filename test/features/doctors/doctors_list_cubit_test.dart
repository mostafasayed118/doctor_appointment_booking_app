import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart' as core;
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/doctors_repository.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/use_cases/get_doctors.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/doctors_list_cubit.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/doctors_state.dart';

class MockDoctorsRepository extends Mock implements DoctorsRepository {}

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

  late MockDoctorsRepository repository;

  setUp(() {
    repository = MockDoctorsRepository();
  });

  DoctorsListCubit buildCubit() =>
      DoctorsListCubit(getDoctors: GetDoctors(repository));

  group('load', () {
    blocTest<DoctorsListCubit, DoctorsState>(
      'emits Loading then Loaded with the doctors',
      build: buildCubit,
      setUp: () => when(() => repository.getDoctors())
          .thenAnswer((_) async => Success([ana, omar])),
      act: (cubit) => cubit.load(),
      expect: () => [
        const DoctorsLoading(),
        DoctorsLoaded(allDoctors: [ana, omar], filteredDoctors: [ana, omar]),
      ],
    );

    blocTest<DoctorsListCubit, DoctorsState>(
      'emits Loading then Loaded-empty when there are no doctors',
      build: buildCubit,
      setUp: () => when(() => repository.getDoctors())
          .thenAnswer((_) async => const Success([])),
      act: (cubit) => cubit.load(),
      expect: () => [
        const DoctorsLoading(),
        const DoctorsLoaded(allDoctors: [], filteredDoctors: []),
      ],
    );

    blocTest<DoctorsListCubit, DoctorsState>(
      'emits Error when the load fails',
      build: buildCubit,
      setUp: () => when(() => repository.getDoctors())
          .thenAnswer((_) async => const Failure(core.NetworkError())),
      act: (cubit) => cubit.load(),
      expect: () => const [
        DoctorsLoading(),
        DoctorsError(core.NetworkError()),
      ],
    );
  });

  group('search (client-side, over the loaded list)', () {
    blocTest<DoctorsListCubit, DoctorsState>(
      'filters by name',
      build: buildCubit,
      seed: () => DoctorsLoaded(
        allDoctors: [ana, omar],
        filteredDoctors: [ana, omar],
      ),
      act: (cubit) => cubit.search('ana'),
      expect: () => [
        DoctorsLoaded(
          allDoctors: [ana, omar],
          filteredDoctors: [ana],
          query: 'ana',
        ),
      ],
    );

    blocTest<DoctorsListCubit, DoctorsState>(
      'clearing the query restores the full list',
      build: buildCubit,
      seed: () => DoctorsLoaded(
        allDoctors: [ana, omar],
        filteredDoctors: [ana],
        query: 'ana',
      ),
      act: (cubit) => cubit.search(''),
      expect: () => [
        DoctorsLoaded(
          allDoctors: [ana, omar],
          filteredDoctors: [ana, omar],
          query: '',
        ),
      ],
    );

    blocTest<DoctorsListCubit, DoctorsState>(
      'is a no-op before anything is loaded',
      build: buildCubit,
      act: (cubit) => cubit.search('ana'),
      expect: () => const <DoctorsState>[],
    );
  });

  group('filterBySpecialty', () {
    blocTest<DoctorsListCubit, DoctorsState>(
      'narrows to the selected specialty',
      build: buildCubit,
      seed: () => DoctorsLoaded(
        allDoctors: [ana, omar],
        filteredDoctors: [ana, omar],
      ),
      act: (cubit) => cubit.filterBySpecialty('Cardiology'),
      expect: () => [
        DoctorsLoaded(
          allDoctors: [ana, omar],
          filteredDoctors: [ana],
          selectedSpecialty: 'Cardiology',
        ),
      ],
    );

    blocTest<DoctorsListCubit, DoctorsState>(
      'null clears the filter',
      build: buildCubit,
      seed: () => DoctorsLoaded(
        allDoctors: [ana, omar],
        filteredDoctors: [ana],
        selectedSpecialty: 'Cardiology',
      ),
      act: (cubit) => cubit.filterBySpecialty(null),
      expect: () => [
        DoctorsLoaded(
          allDoctors: [ana, omar],
          filteredDoctors: [ana, omar],
          selectedSpecialty: null,
        ),
      ],
    );

    blocTest<DoctorsListCubit, DoctorsState>(
      'composes with an active search query',
      build: buildCubit,
      seed: () => DoctorsLoaded(
        allDoctors: [ana, omar],
        filteredDoctors: [ana, omar],
        query: 'ana',
      ),
      act: (cubit) => cubit.filterBySpecialty('Dermatology'),
      expect: () => [
        DoctorsLoaded(
          allDoctors: [ana, omar],
          filteredDoctors: [],
          query: 'ana',
          selectedSpecialty: 'Dermatology',
        ),
      ],
    );
  });
}

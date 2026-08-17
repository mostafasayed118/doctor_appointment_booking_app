import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart'
    as core;
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/appointments/domain/use_cases/cancel_appointment.dart';
import 'package:doctor_appointment_booking_app/features/appointments/domain/use_cases/get_appointments.dart';
import 'package:doctor_appointment_booking_app/features/appointments/presentation/appointments_cubit.dart';
import 'package:doctor_appointment_booking_app/features/appointments/presentation/appointments_state.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/use_cases/get_doctors.dart';

class MockGetAppointments extends Mock implements GetAppointments {}

class MockCancelAppointment extends Mock implements CancelAppointment {}

class MockGetDoctors extends Mock implements GetDoctors {}

// Fixed timestamps everywhere: DateTime.now() would differ between the stub
// and the expectation (Equatable compares), making tests flaky. `now` is
// injected at Aug 17 12:00 UTC.
final now = DateTime.utc(2026, 8, 17, 12);

final doctor = Doctor(
  id: 'd1',
  name: 'Dr. Amina',
  specialty: 'Cardiology',
  bio: 'bio',
  rating: 4.5,
  clinicAddress: 'Clinic 1',
  photoUrl: '',
);

Appointment appointment({
  required String id,
  required DateTime start,
  AppointmentStatus status = AppointmentStatus.scheduled,
}) =>
    Appointment(
      id: id,
      patientId: 'p1',
      doctorId: 'd1',
      slotId: 's-$id',
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
      status: status,
      createdAt: DateTime.utc(2026, 8, 1, 12),
      cancelledAt: status == AppointmentStatus.cancelled
          ? DateTime.utc(2026, 8, 10, 12)
          : null,
    );

// One of each split case: future scheduled → upcoming; past scheduled,
// cancelled, and completed → past.
final futureScheduled = appointment(
  id: 'a1',
  start: DateTime.utc(2026, 8, 20, 9),
);
final cancelledFutureScheduled = appointment(
  id: 'a1',
  start: DateTime.utc(2026, 8, 20, 9),
  status: AppointmentStatus.cancelled,
);
final pastScheduled = appointment(
  id: 'a2',
  start: DateTime.utc(2026, 8, 15, 9),
);
final cancelledAppt = appointment(
  id: 'a3',
  start: DateTime.utc(2026, 8, 21, 9),
  status: AppointmentStatus.cancelled,
);
final completedAppt = appointment(
  id: 'a4',
  start: DateTime.utc(2026, 8, 14, 9),
  status: AppointmentStatus.completed,
);

void main() {
  late MockGetAppointments getAppointments;
  late MockCancelAppointment cancelAppointment;
  late MockGetDoctors getDoctors;

  setUp(() {
    getAppointments = MockGetAppointments();
    cancelAppointment = MockCancelAppointment();
    getDoctors = MockGetDoctors();
    when(() => getDoctors()).thenAnswer((_) async => Success([doctor]));
  });

  AppointmentsCubit buildCubit() => AppointmentsCubit(
    getAppointments: getAppointments,
    cancelAppointment: cancelAppointment,
    getDoctors: getDoctors,
    now: () => now,
  );

  group('initial state', () {
    test('starts in AppointmentsInitial', () {
      expect(buildCubit().state, const AppointmentsInitial());
    });
  });

  group('load', () {
    blocTest<AppointmentsCubit, AppointmentsState>(
      'splits appointments into upcoming and past around the injected now',
      build: buildCubit,
      setUp: () => when(() => getAppointments('p1')).thenAnswer(
        (_) async => Success([
          pastScheduled,
          futureScheduled,
          completedAppt,
          cancelledAppt,
        ]),
      ),
      act: (cubit) => cubit.load('p1'),
      expect: () => [
        const AppointmentsLoading(),
        AppointmentsLoaded(
          upcoming: [futureScheduled],
          past: [pastScheduled, completedAppt, cancelledAppt],
          doctorsById: {'d1': doctor},
        ),
      ],
    );

    blocTest<AppointmentsCubit, AppointmentsState>(
      'emits an empty upcoming and past for a patient with no appointments',
      build: buildCubit,
      setUp: () => when(() => getAppointments('p1'))
          .thenAnswer((_) async => const Success([])),
      act: (cubit) => cubit.load('p1'),
      expect: () => [
        const AppointmentsLoading(),
        AppointmentsLoaded(
          upcoming: [],
          past: [],
          doctorsById: {'d1': doctor},
        ),
      ],
    );

    blocTest<AppointmentsCubit, AppointmentsState>(
      'emits Error when the appointments load fails',
      build: buildCubit,
      setUp: () => when(() => getAppointments('p1'))
          .thenAnswer((_) async => const Failure(core.NetworkError())),
      act: (cubit) => cubit.load('p1'),
      expect: () => [
        const AppointmentsLoading(),
        const AppointmentsError(core.NetworkError()),
      ],
    );

    blocTest<AppointmentsCubit, AppointmentsState>(
      'emits Error when the doctors lookup load fails',
      build: buildCubit,
      setUp: () {
        when(() => getAppointments('p1'))
            .thenAnswer((_) async => Success([futureScheduled]));
        when(() => getDoctors())
            .thenAnswer((_) async => const Failure(core.NetworkError()));
      },
      act: (cubit) => cubit.load('p1'),
      expect: () => [
        const AppointmentsLoading(),
        const AppointmentsError(core.NetworkError()),
      ],
    );
  });

  group('retry', () {
    blocTest<AppointmentsCubit, AppointmentsState>(
      'reloads the last patient after an error',
      build: buildCubit,
      setUp: () {
        var calls = 0;
        when(() => getAppointments('p1')).thenAnswer((_) async {
          calls++;
          return calls == 1
              ? const Failure(core.NetworkError())
              : Success([futureScheduled]);
        });
      },
      act: (cubit) async {
        await cubit.load('p1');
        cubit.retry();
      },
      verify: (_) => verify(() => getAppointments('p1')).called(2),
      expect: () => [
        const AppointmentsLoading(),
        const AppointmentsError(core.NetworkError()),
        const AppointmentsLoading(),
        AppointmentsLoaded(
          upcoming: [futureScheduled],
          past: [],
          doctorsById: {'d1': doctor},
        ),
      ],
    );

    blocTest<AppointmentsCubit, AppointmentsState>(
      'is a no-op before any load ran',
      build: buildCubit,
      act: (cubit) => cubit.retry(),
      expect: () => const <AppointmentsState>[],
    );
  });

  group('cancel', () {
    blocTest<AppointmentsCubit, AppointmentsState>(
      'moves the cancelled appointment to past after a successful cancel',
      build: buildCubit,
      setUp: () {
        var reads = 0;
        when(() => getAppointments('p1')).thenAnswer((_) async {
          reads++;
          // First read: a1 scheduled. After the cancel transaction the
          // reload reads the authoritative Firestore state back — a1 is now
          // cancelled, so it moves to past.
          return Success(reads == 1
              ? [futureScheduled, cancelledAppt]
              : [cancelledFutureScheduled, cancelledAppt]);
        });
        when(
          () => cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
        ).thenAnswer((_) async => Success(cancelledFutureScheduled));
      },
      act: (cubit) async {
        await cubit.load('p1');
        await cubit.cancel('a1');
      },
      expect: () => [
        const AppointmentsLoading(),
        AppointmentsLoaded(
          upcoming: [futureScheduled],
          past: [cancelledAppt],
          doctorsById: {'d1': doctor},
        ),
        AppointmentsLoaded(
          upcoming: [futureScheduled],
          past: [cancelledAppt],
          doctorsById: {'d1': doctor},
          cancellingId: 'a1',
        ),
        AppointmentsLoaded(
          upcoming: [],
          past: [cancelledFutureScheduled, cancelledAppt],
          doctorsById: {'d1': doctor},
        ),
      ],
    );

    blocTest<AppointmentsCubit, AppointmentsState>(
      'surfaces AppointmentAlreadyCancelledError when the cancel fails',
      build: buildCubit,
      setUp: () {
        when(() => getAppointments('p1'))
            .thenAnswer((_) async => Success([futureScheduled]));
        when(
          () => cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
        ).thenAnswer(
          (_) async =>
              const Failure(core.AppointmentAlreadyCancelledError()),
        );
      },
      act: (cubit) async {
        await cubit.load('p1');
        await cubit.cancel('a1');
      },
      expect: () => [
        const AppointmentsLoading(),
        AppointmentsLoaded(
          upcoming: [futureScheduled],
          past: [],
          doctorsById: {'d1': doctor},
        ),
        AppointmentsLoaded(
          upcoming: [futureScheduled],
          past: [],
          doctorsById: {'d1': doctor},
          cancellingId: 'a1',
        ),
        const AppointmentsError(core.AppointmentAlreadyCancelledError()),
      ],
    );

    blocTest<AppointmentsCubit, AppointmentsState>(
      'ignores a second cancel while one is in flight (double-tap guard)',
      build: buildCubit,
      setUp: () {
        when(() => getAppointments('p1'))
            .thenAnswer((_) async => Success([futureScheduled]));
        when(
          () => cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
        ).thenAnswer((_) async => Success(cancelledAppt));
      },
      act: (cubit) async {
        await cubit.load('p1');
        // Fire the first cancel WITHOUT awaiting it: a real double-tap hits
        // the second cancel while the first transaction is still in flight,
        // when the cancellingId guard is actually set.
        cubit.cancel('a1');
        await cubit.cancel('a1');
      },
      verify: (_) =>
          verify(() => cancelAppointment(patientId: 'p1', appointmentId: 'a1'))
              .called(1),
      expect: () => [
        const AppointmentsLoading(),
        AppointmentsLoaded(
          upcoming: [futureScheduled],
          past: [],
          doctorsById: {'d1': doctor},
        ),
        AppointmentsLoaded(
          upcoming: [futureScheduled],
          past: [],
          doctorsById: {'d1': doctor},
          cancellingId: 'a1',
        ),
        // The reload re-reads the same (uncancelled) list — a1 is still
        // upcoming; the important assertion is the verify above (one call).
        AppointmentsLoaded(
          upcoming: [futureScheduled],
          past: [],
          doctorsById: {'d1': doctor},
        ),
      ],
    );

    blocTest<AppointmentsCubit, AppointmentsState>(
      'is a no-op before the list is loaded',
      build: buildCubit,
      seed: () => const AppointmentsInitial(),
      act: (cubit) => cubit.cancel('a1'),
      verify: (_) => verifyNever(
        () => cancelAppointment(
          patientId: any(named: 'patientId'),
          appointmentId: any(named: 'appointmentId'),
        ),
      ),
      expect: () => const <AppointmentsState>[],
    );
  });
}

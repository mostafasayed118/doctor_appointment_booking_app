import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/core/entities/time_slot.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart'
    as core;
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/booking/domain/use_cases/book_slot.dart';
import 'package:doctor_appointment_booking_app/features/booking/domain/use_cases/reschedule_appointment.dart';
import 'package:doctor_appointment_booking_app/features/booking/presentation/booking_cubit.dart';
import 'package:doctor_appointment_booking_app/features/booking/presentation/booking_state.dart';

class MockBookSlot extends Mock implements BookSlot {}

class MockRescheduleAppointment extends Mock
    implements RescheduleAppointment {}

TimeSlot slot(String id) => TimeSlot(
  id: id,
  doctorId: 'd1',
  startTime: DateTime.utc(2026, 8, 20, 9),
  endTime: DateTime.utc(2026, 8, 20, 10),
  isBooked: false,
);// Fixed createdAt: DateTime.now() here would differ between the stub and
// the expectation (Equatable compares it), making the test flaky.
Appointment appointment() => Appointment(
      id: 'appt-1',
      patientId: 'p1',
      doctorId: 'd1',
      slotId: 's1',
      startTime: DateTime.utc(2026, 8, 20, 9),
      endTime: DateTime.utc(2026, 8, 20, 10),
      status: AppointmentStatus.scheduled,
      createdAt: DateTime.utc(2026, 8, 17, 12),
    );

void main() {
  late MockBookSlot bookSlot;
  late MockRescheduleAppointment rescheduleAppointment;

  setUp(() {
    bookSlot = MockBookSlot();
    rescheduleAppointment = MockRescheduleAppointment();
  });

  BookingCubit buildCubit() => BookingCubit(
    bookSlot: bookSlot,
    rescheduleAppointment: rescheduleAppointment,
  );

  group('initial state', () {
    test('starts in BookingInitial', () {
      expect(buildCubit().state, const BookingInitial());
    });
  });

  group('confirm', () {
    blocTest<BookingCubit, BookingState>(
      'emits Confirming then Confirmed on success',
      build: buildCubit,
      setUp: () => when(
        () => bookSlot(patientId: 'p1', slotId: 's1'),
      ).thenAnswer((_) async => Success(appointment())),
      act: (cubit) => cubit.confirm(patientId: 'p1', slot: slot('s1')),
      expect: () => [
        const BookingConfirming(),
        BookingConfirmed(appointment()),
      ],
    );

    blocTest<BookingCubit, BookingState>(
      'emits Error with SlotUnavailableError when the slot was taken',
      build: buildCubit,
      setUp: () => when(
        () => bookSlot(patientId: 'p1', slotId: 's1'),
      ).thenAnswer((_) async => const Failure(core.SlotUnavailableError())),
      act: (cubit) => cubit.confirm(patientId: 'p1', slot: slot('s1')),
      expect: () => [
        const BookingConfirming(),
        const BookingError(core.SlotUnavailableError()),
      ],
    );

    blocTest<BookingCubit, BookingState>(
      'emits Error with NotFoundError when the slot document is missing',
      build: buildCubit,
      setUp: () => when(
        () => bookSlot(patientId: 'p1', slotId: 's1'),
      ).thenAnswer((_) async => const Failure(core.NotFoundError())),
      act: (cubit) => cubit.confirm(patientId: 'p1', slot: slot('s1')),
      expect: () => [
        const BookingConfirming(),
        const BookingError(core.NotFoundError()),
      ],
    );

    blocTest<BookingCubit, BookingState>(
      'emits Error with NetworkError on a transient failure',
      build: buildCubit,
      setUp: () => when(
        () => bookSlot(patientId: 'p1', slotId: 's1'),
      ).thenAnswer((_) async => const Failure(core.NetworkError())),
      act: (cubit) => cubit.confirm(patientId: 'p1', slot: slot('s1')),
      expect: () => [
        const BookingConfirming(),
        const BookingError(core.NetworkError()),
      ],
    );
  });

  group('reschedule', () {
    blocTest<BookingCubit, BookingState>(
      'emits Confirming then Rescheduled on success',
      build: buildCubit,
      setUp: () => when(
        () => rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 's2',
        ),
      ).thenAnswer((_) async => Success(appointment())),
      act: (cubit) => cubit.reschedule(
        patientId: 'p1',
        appointmentId: 'a1',
        newSlot: slot('s2'),
      ),
      expect: () => [
        const BookingConfirming(),
        BookingRescheduled(appointment()),
      ],
    );

    blocTest<BookingCubit, BookingState>(
      'emits Error with SlotUnavailableError when the new slot was taken',
      build: buildCubit,
      setUp: () => when(
        () => rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 's2',
        ),
      ).thenAnswer((_) async => const Failure(core.SlotUnavailableError())),
      act: (cubit) => cubit.reschedule(
        patientId: 'p1',
        appointmentId: 'a1',
        newSlot: slot('s2'),
      ),
      expect: () => [
        const BookingConfirming(),
        const BookingError(core.SlotUnavailableError()),
      ],
    );
  });

  group('retry', () {
    blocTest<BookingCubit, BookingState>(
      're-runs confirm with the last patient and slot after an error',
      build: buildCubit,
      setUp: () => when(
        () => bookSlot(patientId: 'p1', slotId: 's1'),
      ).thenAnswer((_) async => const Failure(core.NetworkError())),
      act: (cubit) async {
        await cubit.confirm(patientId: 'p1', slot: slot('s1'));
        cubit.retry();
      },
      verify: (_) =>
          verify(() => bookSlot(patientId: 'p1', slotId: 's1')).called(2),
      expect: () => [
        const BookingConfirming(),
        const BookingError(core.NetworkError()),
        const BookingConfirming(),
        const BookingError(core.NetworkError()),
      ],
    );

    blocTest<BookingCubit, BookingState>(
      're-runs the last reschedule after an error',
      build: buildCubit,
      setUp: () => when(
        () => rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 's2',
        ),
      ).thenAnswer((_) async => const Failure(core.NetworkError())),
      act: (cubit) async {
        await cubit.reschedule(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlot: slot('s2'),
        );
        cubit.retry();
      },
      verify: (_) => verify(
        () => rescheduleAppointment(
          patientId: 'p1',
          appointmentId: 'a1',
          newSlotId: 's2',
        ),
      ).called(2),
      expect: () => [
        const BookingConfirming(),
        const BookingError(core.NetworkError()),
        const BookingConfirming(),
        const BookingError(core.NetworkError()),
      ],
    );

    blocTest<BookingCubit, BookingState>(
      'is a no-op before any confirm ran',
      build: buildCubit,
      seed: () => const BookingInitial(),
      act: (cubit) => cubit.retry(),
      expect: () => const <BookingState>[],
    );
  });

  group('reset', () {
    blocTest<BookingCubit, BookingState>(
      'returns to BookingInitial',
      build: buildCubit,
      seed: () => BookingConfirmed(appointment()),
      act: (cubit) => cubit.reset(),
      expect: () => const [BookingInitial()],
    );
  });
}

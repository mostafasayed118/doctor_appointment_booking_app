import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/time_slot.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart' as core;
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/booking/domain/slots_repository.dart';
import 'package:doctor_appointment_booking_app/features/booking/domain/use_cases/get_slots.dart';
import 'package:doctor_appointment_booking_app/features/booking/presentation/slot_grouping.dart';
import 'package:doctor_appointment_booking_app/features/booking/presentation/slot_selection_cubit.dart';
import 'package:doctor_appointment_booking_app/features/booking/presentation/slot_selection_state.dart';

class MockSlotsRepository extends Mock implements SlotsRepository {}

TimeSlot slot(String id, DateTime start, {bool isBooked = false}) => TimeSlot(
      id: id,
      doctorId: 'd1',
      startTime: start,
      endTime: start.add(const Duration(hours: 1)),
      isBooked: isBooked,
    );

void main() {
  final now = DateTime(2026, 8, 14, 12);

  late MockSlotsRepository repository;

  setUp(() {
    repository = MockSlotsRepository();
  });

  SlotSelectionCubit buildCubit() => SlotSelectionCubit(
        getSlots: GetSlots(repository),
        now: () => now,
      );

  group('load', () {
    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'emits Loading then Loaded with days grouped by local date',
      build: buildCubit,
      setUp: () => when(() => repository.getSlots('d1')).thenAnswer(
        (_) async => Success([
          slot('a', DateTime(2026, 8, 15, 9)),
          slot('b', DateTime(2026, 8, 15, 10)),
          slot('c', DateTime(2026, 8, 16, 9)),
        ]),
      ),
      act: (cubit) => cubit.load('d1'),
      expect: () => [
        const SlotSelectionLoading(),
        SlotSelectionLoaded(
          doctorId: 'd1',
          days: [
            SlotDay(day: DateTime(2026, 8, 15), slots: [
              slot('a', DateTime(2026, 8, 15, 9)),
              slot('b', DateTime(2026, 8, 15, 10)),
            ]),
            SlotDay(day: DateTime(2026, 8, 16), slots: [
              slot('c', DateTime(2026, 8, 16, 9)),
            ]),
          ],
        ),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'filters past and booked slots out of the days',
      build: buildCubit,
      setUp: () => when(() => repository.getSlots('d1')).thenAnswer(
        (_) async => Success([
          slot('past', now.subtract(const Duration(hours: 1))),
          slot('taken', now.add(const Duration(hours: 1)), isBooked: true),
          slot('free', now.add(const Duration(hours: 2))),
        ]),
      ),
      act: (cubit) => cubit.load('d1'),
      expect: () => [
        const SlotSelectionLoading(),
        SlotSelectionLoaded(
          doctorId: 'd1',
          days: [
            SlotDay(day: DateTime(2026, 8, 14), slots: [
              slot('free', now.add(const Duration(hours: 2))),
            ]),
          ],
        ),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'excludes the current slot in reschedule mode',
      build: buildCubit,
      setUp: () => when(() => repository.getSlots('d1')).thenAnswer(
        (_) async => Success([
          slot('current', DateTime(2026, 8, 15, 9)),
          slot('other', DateTime(2026, 8, 15, 10)),
        ]),
      ),
      act: (cubit) => cubit.load('d1', excludedSlotId: 'current'),
      expect: () => [
        const SlotSelectionLoading(),
        SlotSelectionLoaded(
          doctorId: 'd1',
          days: [
            SlotDay(day: DateTime(2026, 8, 15), slots: [
              slot('other', DateTime(2026, 8, 15, 10)),
            ]),
          ],
        ),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'emits Loaded with empty days when there are no slots',
      build: buildCubit,
      setUp: () => when(() => repository.getSlots('d1'))
          .thenAnswer((_) async => const Success([])),
      act: (cubit) => cubit.load('d1'),
      expect: () => [
        const SlotSelectionLoading(),
        const SlotSelectionLoaded(doctorId: 'd1', days: []),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'emits Error when the load fails',
      build: buildCubit,
      setUp: () => when(() => repository.getSlots('d1'))
          .thenAnswer((_) async => const Failure(core.NetworkError())),
      act: (cubit) => cubit.load('d1'),
      expect: () => const [
        SlotSelectionLoading(),
        SlotSelectionError(core.NetworkError()),
      ],
    );
  });

  group('retry', () {
    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'retry keeps the excluded slot from the reschedule load',
      build: buildCubit,
      setUp: () {
        var failFirst = true;
        when(() => repository.getSlots('d1')).thenAnswer((_) async {
          if (failFirst) {
            failFirst = false;
            return const Failure(core.NetworkError());
          }
          return Success([
            slot('current', DateTime(2026, 8, 15, 9)),
            slot('other', DateTime(2026, 8, 15, 10)),
          ]);
        });
      },
      act: (cubit) async {
        await cubit.load('d1', excludedSlotId: 'current');
        cubit.retry();
      },
      expect: () => [
        const SlotSelectionLoading(),
        const SlotSelectionError(core.NetworkError()),
        const SlotSelectionLoading(),
        SlotSelectionLoaded(
          doctorId: 'd1',
          days: [
            SlotDay(day: DateTime(2026, 8, 15), slots: [
              slot('other', DateTime(2026, 8, 15, 10)),
            ]),
          ],
        ),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'reloads the last requested doctor after an error',
      build: buildCubit,
      setUp: () {
        // First load fails; retry's reload succeeds. mocktail's thenAnswer
        // returns void, so vary the result with a mutable flag instead of
        // chaining answers.
        var failFirst = true;
        when(() => repository.getSlots('d1')).thenAnswer((_) async {
          if (failFirst) {
            failFirst = false;
            return const Failure(core.NetworkError());
          }
          return Success([slot('a', DateTime(2026, 8, 15, 9))]);
        });
      },
      act: (cubit) async {
        await cubit.load('d1');
        cubit.retry();
      },
      expect: () => [
        const SlotSelectionLoading(),
        const SlotSelectionError(core.NetworkError()),
        const SlotSelectionLoading(),
        SlotSelectionLoaded(
          doctorId: 'd1',
          days: [
            SlotDay(day: DateTime(2026, 8, 15), slots: [
              slot('a', DateTime(2026, 8, 15, 9)),
            ]),
          ],
        ),
      ],
    );
  });

  group('selectDay', () {
    final loaded = SlotSelectionLoaded(
      doctorId: 'd1',
      days: [
        SlotDay(day: DateTime(2026, 8, 15), slots: [
          slot('a', DateTime(2026, 8, 15, 9)),
        ]),
        SlotDay(day: DateTime(2026, 8, 16), slots: [
          slot('b', DateTime(2026, 8, 16, 9)),
        ]),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'switches the selected day',
      build: buildCubit,
      seed: () => loaded,
      act: (cubit) => cubit.selectDay(1),
      expect: () => [
        SlotSelectionLoaded(
          doctorId: 'd1',
          days: loaded.days,
          selectedDayIndex: 1,
        ),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'is a no-op outside the day range',
      build: buildCubit,
      seed: () => loaded,
      act: (cubit) => cubit.selectDay(5),
      expect: () => const <SlotSelectionState>[],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'clears the selected slot when switching days',
      build: buildCubit,
      seed: () => SlotSelectionLoaded(
        doctorId: 'd1',
        days: loaded.days,
        selectedSlot: slot('a', DateTime(2026, 8, 15, 9)),
      ),
      act: (cubit) => cubit.selectDay(1),
      expect: () => [
        SlotSelectionLoaded(
          doctorId: 'd1',
          days: loaded.days,
          selectedDayIndex: 1,
        ),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'is a no-op before anything is loaded',
      build: buildCubit,
      act: (cubit) => cubit.selectDay(0),
      expect: () => const <SlotSelectionState>[],
    );
  });

  group('selectSlot / clearSelection', () {
    final day = SlotDay(day: DateTime(2026, 8, 15), slots: [
      slot('a', DateTime(2026, 8, 15, 9)),
    ]);

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'records the tapped slot as selected',
      build: buildCubit,
      seed: () => SlotSelectionLoaded(doctorId: 'd1', days: [day]),
      act: (cubit) => cubit.selectSlot(slot('a', DateTime(2026, 8, 15, 9))),
      expect: () => [
        SlotSelectionLoaded(
          doctorId: 'd1',
          days: [day],
          selectedSlot: slot('a', DateTime(2026, 8, 15, 9)),
        ),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'clearSelection drops the selected slot',
      build: buildCubit,
      seed: () => SlotSelectionLoaded(
        doctorId: 'd1',
        days: [day],
        selectedSlot: slot('a', DateTime(2026, 8, 15, 9)),
      ),
      act: (cubit) => cubit.clearSelection(),
      expect: () => [
        SlotSelectionLoaded(doctorId: 'd1', days: [day]),
      ],
    );

    blocTest<SlotSelectionCubit, SlotSelectionState>(
      'is a no-op before anything is loaded',
      build: buildCubit,
      act: (cubit) => cubit.selectSlot(slot('a', DateTime(2026, 8, 15, 9))),
      expect: () => const <SlotSelectionState>[],
    );
  });
}

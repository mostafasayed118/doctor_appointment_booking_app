import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/time_slot.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/data/error/firebase_error_mapper.dart';
import 'package:doctor_appointment_booking_app/features/booking/data/firestore_slots_data_source.dart';
import 'package:doctor_appointment_booking_app/features/booking/data/slots_repository_impl.dart';

class MockSlotsDataSource extends Mock implements FirestoreSlotsDataSource {}

void main() {
  final start = DateTime.utc(2026, 8, 15, 9);

  late MockSlotsDataSource dataSource;
  late SlotsRepositoryImpl repository;

  setUp(() {
    dataSource = MockSlotsDataSource();
    repository = SlotsRepositoryImpl(
      dataSource: dataSource,
      mapper: const FirebaseErrorMapper(),
    );
  });

  group('getSlots', () {
    test('returns Success with the slots', () async {
      final slots = [
        TimeSlot(
          id: 's1',
          doctorId: 'd1',
          startTime: start,
          endTime: start.add(const Duration(hours: 1)),
          isBooked: false,
        ),
      ];
      when(() => dataSource.fetchSlots('d1')).thenAnswer((_) async => slots);

      final result = await repository.getSlots('d1');

      expect(result, isA<Success<List<TimeSlot>>>());
      expect((result as Success<List<TimeSlot>>).value, slots);
    });

    test('maps a Firestore network error to Failure<NetworkError>', () async {
      when(() => dataSource.fetchSlots('d1')).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      final result = await repository.getSlots('d1');

      expect((result as Failure<List<TimeSlot>>).error, isA<NetworkError>());
    });

    test('maps unexpected errors to Failure<UnexpectedError>', () async {
      when(() => dataSource.fetchSlots('d1')).thenThrow(StateError('boom'));

      final result = await repository.getSlots('d1');

      expect((result as Failure<List<TimeSlot>>).error, isA<UnexpectedError>());
    });
  });
}

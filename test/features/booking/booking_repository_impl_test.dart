import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/data/error/firebase_error_mapper.dart';
import 'package:doctor_appointment_booking_app/features/booking/data/booking_repository_impl.dart';
import 'package:doctor_appointment_booking_app/features/booking/data/firestore_booking_data_source.dart';

class MockBookingDataSource extends Mock
    implements FirestoreBookingDataSource {}

void main() {
  final appointment = Appointment(
    id: 'appt-1',
    patientId: 'p1',
    doctorId: 'd1',
    slotId: 's1',
    startTime: DateTime.utc(2026, 8, 20, 9),
    endTime: DateTime.utc(2026, 8, 20, 10),
    status: AppointmentStatus.scheduled,
    createdAt: DateTime.now(),
  );

  late MockBookingDataSource dataSource;
  late BookingRepositoryImpl repository;

  setUp(() {
    dataSource = MockBookingDataSource();
    repository = BookingRepositoryImpl(
      dataSource: dataSource,
      mapper: const FirebaseErrorMapper(),
    );
  });

  group('bookSlot', () {
    test('returns Success with the created appointment', () async {
      when(
        () => dataSource.bookSlot(patientId: 'p1', slotId: 's1'),
      ).thenAnswer((_) async => appointment);

      final result = await repository.bookSlot(patientId: 'p1', slotId: 's1');

      expect(result, isA<Success<Appointment>>());
      expect((result as Success<Appointment>).value, appointment);
    });

    test('maps the business rule to Failure<SlotUnavailableError>', () async {
      when(
        () => dataSource.bookSlot(patientId: 'p1', slotId: 's1'),
      ).thenThrow(const SlotUnavailableException());

      final result = await repository.bookSlot(patientId: 'p1', slotId: 's1');

      expect(
        (result as Failure<Appointment>).error,
        isA<SlotUnavailableError>(),
      );
    });

    test('maps a missing slot to Failure<NotFoundError>', () async {
      when(() => dataSource.bookSlot(patientId: 'p1', slotId: 's1')).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Slot s1 was not found.',
        ),
      );

      final result = await repository.bookSlot(patientId: 'p1', slotId: 's1');

      expect((result as Failure<Appointment>).error, isA<NotFoundError>());
    });

    test('maps a network failure to Failure<NetworkError>', () async {
      when(() => dataSource.bookSlot(patientId: 'p1', slotId: 's1')).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      final result = await repository.bookSlot(patientId: 'p1', slotId: 's1');

      expect((result as Failure<Appointment>).error, isA<NetworkError>());
    });

    test('maps unexpected errors to Failure<UnexpectedError>', () async {
      when(
        () => dataSource.bookSlot(patientId: 'p1', slotId: 's1'),
      ).thenThrow(StateError('boom'));

      final result = await repository.bookSlot(patientId: 'p1', slotId: 's1');

      expect((result as Failure<Appointment>).error, isA<UnexpectedError>());
    });
  });
}

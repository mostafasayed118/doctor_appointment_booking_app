import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/data/error/firebase_error_mapper.dart';
import 'package:doctor_appointment_booking_app/features/appointments/data/appointments_repository_impl.dart';
import 'package:doctor_appointment_booking_app/features/appointments/data/firestore_appointments_data_source.dart';

class MockAppointmentsDataSource extends Mock
    implements FirestoreAppointmentsDataSource {}

void main() {
  final appointment = Appointment(
    id: 'appt-1',
    patientId: 'p1',
    doctorId: 'd1',
    slotId: 's1',
    startTime: DateTime.utc(2026, 8, 20, 9),
    endTime: DateTime.utc(2026, 8, 20, 10),
    status: AppointmentStatus.scheduled,
    createdAt: DateTime.utc(2026, 8, 17, 12),
  );
  final cancelled = Appointment(
    id: 'appt-1',
    patientId: 'p1',
    doctorId: 'd1',
    slotId: 's1',
    startTime: DateTime.utc(2026, 8, 20, 9),
    endTime: DateTime.utc(2026, 8, 20, 10),
    status: AppointmentStatus.cancelled,
    createdAt: DateTime.utc(2026, 8, 17, 12),
    cancelledAt: DateTime.utc(2026, 8, 18, 12),
  );

  late MockAppointmentsDataSource dataSource;
  late AppointmentsRepositoryImpl repository;

  setUp(() {
    dataSource = MockAppointmentsDataSource();
    repository = AppointmentsRepositoryImpl(
      dataSource: dataSource,
      mapper: const FirebaseErrorMapper(),
    );
  });

  group('getAppointments', () {
    test('returns Success with the patient\'s appointments', () async {
      when(() => dataSource.getAppointments('p1'))
          .thenAnswer((_) async => [appointment]);

      final result = await repository.getAppointments('p1');

      expect(result, isA<Success<List<Appointment>>>());
      expect((result as Success<List<Appointment>>).value, [appointment]);
    });

    test('maps a network failure to Failure<NetworkError>', () async {
      when(() => dataSource.getAppointments('p1')).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      final result = await repository.getAppointments('p1');

      expect(
        (result as Failure<List<Appointment>>).error,
        isA<NetworkError>(),
      );
    });
  });

  group('cancelAppointment', () {
    test('returns Success with the cancelled appointment', () async {
      when(
        () => dataSource.cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
      ).thenAnswer((_) async => cancelled);

      final result = await repository.cancelAppointment(
        patientId: 'p1',
        appointmentId: 'a1',
      );

      expect(result, isA<Success<Appointment>>());
      expect((result as Success<Appointment>).value, cancelled);
    });

    test(
        'maps the business rule to Failure<AppointmentAlreadyCancelledError>',
        () async {
      when(
        () => dataSource.cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
      ).thenThrow(const AppointmentAlreadyCancelledException());

      final result = await repository.cancelAppointment(
        patientId: 'p1',
        appointmentId: 'a1',
      );

      expect(
        (result as Failure<Appointment>).error,
        isA<AppointmentAlreadyCancelledError>(),
      );
    });

    test('maps a missing/not-owned appointment to Failure<NotFoundError>',
        () async {
      when(
        () => dataSource.cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
      ).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Appointment a1 was not found.',
        ),
      );

      final result = await repository.cancelAppointment(
        patientId: 'p1',
        appointmentId: 'a1',
      );

      expect((result as Failure<Appointment>).error, isA<NotFoundError>());
    });

    test('maps a network failure to Failure<NetworkError>', () async {
      when(
        () => dataSource.cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
      ).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );

      final result = await repository.cancelAppointment(
        patientId: 'p1',
        appointmentId: 'a1',
      );

      expect((result as Failure<Appointment>).error, isA<NetworkError>());
    });

    test('maps unexpected errors to Failure<UnexpectedError>', () async {
      when(
        () => dataSource.cancelAppointment(patientId: 'p1', appointmentId: 'a1'),
      ).thenThrow(StateError('boom'));

      final result = await repository.cancelAppointment(
        patientId: 'p1',
        appointmentId: 'a1',
      );

      expect((result as Failure<Appointment>).error, isA<UnexpectedError>());
    });
  });
}

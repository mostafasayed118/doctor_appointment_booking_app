import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/appointment.dart';
import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/core/entities/time_slot.dart';

void main() {
  group('Doctor', () {
    test('two identical doctors are equal (Equatable)', () {
      const a = Doctor(
        id: '1',
        name: 'Dr. Smith',
        specialty: 'Cardiology',
        bio: 'Bio',
        rating: 4.5,
        clinicAddress: 'Cairo',
        photoUrl: 'http://img',
      );
      const b = Doctor(
        id: '1',
        name: 'Dr. Smith',
        specialty: 'Cardiology',
        bio: 'Bio',
        rating: 4.5,
        clinicAddress: 'Cairo',
        photoUrl: 'http://img',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('doctors differing in any field are not equal', () {
      const a = Doctor(
        id: '1',
        name: 'Dr. Smith',
        specialty: 'Cardiology',
        bio: 'Bio',
        rating: 4.5,
        clinicAddress: 'Cairo',
        photoUrl: 'http://img',
      );
      const b = Doctor(
        id: '1',
        name: 'Dr. Smith',
        specialty: 'Cardiology',
        bio: 'Bio',
        rating: 4.0, // different rating
        clinicAddress: 'Cairo',
        photoUrl: 'http://img',
      );

      expect(a, isNot(equals(b)));
    });
  });

  group('TimeSlot', () {
    test('two identical slots are equal (Equatable)', () {
      final start = DateTime.utc(2026, 8, 13, 14);
      final a = TimeSlot(
        id: 's1',
        doctorId: 'd1',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        isBooked: false,
      );
      final b = TimeSlot(
        id: 's1',
        doctorId: 'd1',
        startTime: start,
        endTime: start.add(const Duration(hours: 1)),
        isBooked: false,
      );

      expect(a, equals(b));
    });
  });

  group('AppointmentStatus', () {
    test('storage name matches the enum name', () {
      expect(AppointmentStatus.scheduled.name, 'scheduled');
      expect(AppointmentStatus.cancelled.name, 'cancelled');
      expect(AppointmentStatus.completed.name, 'completed');
    });
  });
}
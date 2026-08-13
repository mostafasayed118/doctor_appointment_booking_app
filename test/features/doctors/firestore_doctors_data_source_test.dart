import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/features/doctors/data/firestore_doctors_data_source.dart';

Map<String, Object?> doctorDoc({
  String name = 'Ana Patel',
  String specialty = 'Cardiology',
  double rating = 4.8,
}) =>
    {
      'name': name,
      'specialty': specialty,
      'bio': 'Cardiologist with 15 years of experience.',
      'rating': rating,
      'clinicAddress': '12 Medical Ave',
      'photoUrl': 'https://example.com/ana.jpg',
    };

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreDoctorsDataSource dataSource;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreDoctorsDataSource(firestore: firestore);
  });

  group('fetchDoctors', () {
    test('maps every document to a Doctor entity', () async {
      await firestore.collection('doctors').doc('d1').set(doctorDoc());
      await firestore.collection('doctors').doc('d2').set(
            doctorDoc(name: 'Omar Haddad', specialty: 'Dermatology', rating: 4.2),
          );

      final doctors = await dataSource.fetchDoctors();

      expect(doctors, hasLength(2));
      final byId = {for (final d in doctors) d.id: d};

      expect(
        byId['d1'],
        const Doctor(
          id: 'd1',
          name: 'Ana Patel',
          specialty: 'Cardiology',
          bio: 'Cardiologist with 15 years of experience.',
          rating: 4.8,
          clinicAddress: '12 Medical Ave',
          photoUrl: 'https://example.com/ana.jpg',
        ),
      );
      expect(byId['d2']!.name, 'Omar Haddad');
      expect(byId['d2']!.specialty, 'Dermatology');
    });

    test('returns an empty list when the collection is empty', () async {
      expect(await dataSource.fetchDoctors(), isEmpty);
    });
  });

  group('fetchDoctor', () {
    test('maps a single document', () async {
      await firestore.collection('doctors').doc('d1').set(doctorDoc());

      final doctor = await dataSource.fetchDoctor('d1');

      expect(doctor.id, 'd1');
      expect(doctor.name, 'Ana Patel');
      expect(doctor.rating, 4.8);
    });

    test('throws a not-found FirebaseException for a missing document',
        () async {
      await expectLater(
        dataSource.fetchDoctor('nope'),
        throwsA(
          isA<FirebaseException>().having((e) => e.code, 'code', 'not-found'),
        ),
      );
    });
  });
}

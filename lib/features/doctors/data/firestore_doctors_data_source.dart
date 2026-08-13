import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/entities/doctor.dart';

/// The only place in the doctors feature that touches the Firestore SDK.
///
/// Reads the `doctors` collection (schema owned by Task 10's seed script)
/// and converts docs to domain [Doctor]s so nothing above this file ever
/// imports cloud_firestore. The repository catches and maps the SDK's
/// exceptions; this file just talks to Firestore.
///
/// [firestore] is injectable so tests can pass a `FakeFirebaseFirestore`
/// (the real instance blocks on a platform channel that never answers in
/// unit tests).
class FirestoreDoctorsDataSource {
  FirestoreDoctorsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'doctors';

  Future<List<Doctor>> fetchDoctors() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs.map(_toDoctor).toList();
  }

  Future<Doctor> fetchDoctor(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) {
      // doc.get() returns a non-existent snapshot rather than throwing, so
      // raise the SDK-shaped exception the error mapper already knows —
      // missing doctors surface as NotFoundError everywhere above.
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'Doctor $id was not found.',
      );
    }
    return _toDoctor(doc);
  }

  Doctor _toDoctor(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Doctor(
      id: doc.id,
      name: data['name'] as String,
      specialty: data['specialty'] as String,
      bio: data['bio'] as String,
      rating: (data['rating'] as num).toDouble(),
      clinicAddress: data['clinicAddress'] as String,
      photoUrl: data['photoUrl'] as String,
    );
  }
}

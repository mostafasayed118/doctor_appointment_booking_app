import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/entities/time_slot.dart';

/// The only place in the booking feature that touches the Firestore SDK.
///
/// Reads the `slots` collection (schema owned by Task 10's seed script) and
/// converts docs to domain [TimeSlot]s so nothing above this file ever
/// imports cloud_firestore. The repository catches and maps the SDK's
/// exceptions; this file just talks to Firestore.
///
/// [firestore] is injectable so tests can pass a `FakeFirebaseFirestore`
/// (the real instance blocks on a platform channel that never answers in
/// unit tests).
class FirestoreSlotsDataSource {
  FirestoreSlotsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'slots';

  /// All slots for [doctorId], ordered by start time. Single-field
  /// `orderBy` needs no composite index.
  Future<List<TimeSlot>> fetchSlots(String doctorId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('startTime')
        .get();
    return snapshot.docs.map(_toSlot).toList();
  }

  TimeSlot _toSlot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TimeSlot(
      id: doc.id,
      doctorId: data['doctorId'] as String,
      // Timestamp.toDate() yields a *local* DateTime; the entity contract
      // is UTC instants (the UI calls toLocal() when displaying), so
      // normalize here — otherwise equality and day-grouping depend on the
      // device timezone.
      startTime: (data['startTime'] as Timestamp).toDate().toUtc(),
      endTime: (data['endTime'] as Timestamp).toDate().toUtc(),
      isBooked: data['isBooked'] as bool,
    );
  }
}

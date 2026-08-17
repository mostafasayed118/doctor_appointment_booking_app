import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/entities/appointment.dart';

/// Thrown when a slot exists but can no longer be booked (already taken,
/// or its start time has passed).
///
/// Deliberately NOT a Firebase exception: this is our business rule, not an
/// SDK signal, so the repository catches it BEFORE the Firebase error
/// mapper and returns [SlotUnavailableError]. A *missing* slot instead
/// raises a `not-found` FirebaseException (same trick as
/// FirestoreDoctorsDataSource) so the existing mapper yields
/// [NotFoundError].
class SlotUnavailableException implements Exception {
  const SlotUnavailableException();
}

/// The only place in the booking feature that writes appointments.
///
/// [bookSlot] runs ONE transaction over the slot document:
///
///   read   `slots/<slotId>`
///   verify exists, not booked, not in the past
///   write  `slots/<slotId>.isBooked = true`
///          `appointments/<auto>` = {patientId, doctorId, slotId, ...}
///
/// The slot document is the CONCURRENCY UNIT: Firestore serializes
/// transactions on the documents they read, so two devices racing the same
/// slot get one winner. The loser's commit fails the optimistic-concurrency
/// check on the slot doc, Firestore re-runs the callback, and the re-read
/// sees isBooked=true → [SlotUnavailableException]. Without reading the
/// slot inside the transaction, both devices would write and the slot would
/// be double-booked.
class FirestoreBookingDataSource {
  FirestoreBookingDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Appointment> bookSlot({
    required String patientId,
    required String slotId,
  }) async {
    final slotRef = _firestore.collection('slots').doc(slotId);
    final appointmentRef = _firestore.collection('appointments').doc();

    // Captured inside the transaction callback so the returned entity is
    // built from the values the transaction actually committed with (on a
    // retry, slotData reflects the final successful run).
    Map<String, dynamic>? committedSlot;

    await _firestore.runTransaction((transaction) async {
      final slotSnapshot = await transaction.get(slotRef);
      if (!slotSnapshot.exists) {
        // Match the doctors data source pattern: raise the SDK-shaped
        // 'not-found' exception so the mapper yields NotFoundError.
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Slot $slotId was not found.',
        );
      }
      final slot = slotSnapshot.data() as Map<String, dynamic>;
      if (slot['isBooked'] == true) {
        throw const SlotUnavailableException();
      }
      final startTime = (slot['startTime'] as Timestamp).toDate();
      if (!startTime.isAfter(DateTime.now())) {
        throw const SlotUnavailableException();
      }

      committedSlot = slot;
      transaction.update(slotRef, {'isBooked': true});
      transaction.set(appointmentRef, {
        'patientId': patientId,
        'doctorId': slot['doctorId'],
        'slotId': slotId,
        'startTime': slot['startTime'],
        'endTime': slot['endTime'],
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    final slot = committedSlot!;
    return Appointment(
      // doc() generated the id client-side, so it is known without a
      // follow-up read.
      id: appointmentRef.id,
      patientId: patientId,
      doctorId: slot['doctorId'] as String,
      slotId: slotId,
      // Timestamps are UTC instants (see the TimeSlot contract); toDate()
      // yields local, so normalize.
      startTime: (slot['startTime'] as Timestamp).toDate().toUtc(),
      endTime: (slot['endTime'] as Timestamp).toDate().toUtc(),
      status: AppointmentStatus.scheduled,
      // The document carries the authoritative server timestamp; this
      // in-memory value is display-only (Task 13 reads real documents).
      createdAt: DateTime.now(),
    );
  }
}

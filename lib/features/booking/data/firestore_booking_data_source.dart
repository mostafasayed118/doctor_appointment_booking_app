import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/entities/appointment.dart';
import '../../appointments/data/firestore_appointments_data_source.dart'
    show AppointmentAlreadyCancelledException;

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
///
/// [rescheduleAppointment] is the same idea extended to three documents:
/// the new slot is the concurrency unit for the move, the appointment doc
/// (read first) is the ownership record that fixes WHICH slot is freed, and
/// the old slot must still be booked — the guard that makes a stale
/// double-reschedule abort instead of moving the appointment twice.
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

  Future<Appointment> rescheduleAppointment({
    required String patientId,
    required String appointmentId,
    required String newSlotId,
  }) async {
    final appointmentRef =
        _firestore.collection('appointments').doc(appointmentId);
    final newSlotRef = _firestore.collection('slots').doc(newSlotId);

    // Captured inside the transaction callback so the returned entity is
    // built from the values the transaction actually committed with (on a
    // retry, they reflect the final successful run).
    Map<String, dynamic>? committedAppointment;
    Map<String, dynamic>? committedNewSlot;

    await _firestore.runTransaction((transaction) async {
      // --- all reads, before any write (Firestore rule) ---
      final appointmentSnapshot = await transaction.get(appointmentRef);
      if (!appointmentSnapshot.exists) {
        // Match the doctors/booking pattern: raise the SDK-shaped
        // 'not-found' exception so the mapper yields NotFoundError.
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Appointment $appointmentId was not found.',
        );
      }
      final appointment = appointmentSnapshot.data() as Map<String, dynamic>;
      // Ownership check: someone else's appointment is treated as
      // non-existent (standard practice — no info leak, and it reuses the
      // existing NotFoundError path).
      if (appointment['patientId'] != patientId) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Appointment $appointmentId was not found.',
        );
      }
      if (appointment['status'] == 'cancelled') {
        throw const AppointmentAlreadyCancelledException();
      }

      final newSlotSnapshot = await transaction.get(newSlotRef);
      if (!newSlotSnapshot.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Slot $newSlotId was not found.',
        );
      }
      final newSlot = newSlotSnapshot.data() as Map<String, dynamic>;
      if (newSlot['isBooked'] == true) {
        throw const SlotUnavailableException();
      }
      final newStart = (newSlot['startTime'] as Timestamp).toDate();
      if (!newStart.isAfter(DateTime.now())) {
        throw const SlotUnavailableException();
      }

      // The old slot is DERIVED from the appointment doc — the caller can't
      // choose which slot to release. It must still be booked: a free old
      // slot means a concurrent reschedule already moved this appointment,
      // so this run is stale (Firestore retries the callback, making this
      // the guard the loser of a double-reschedule converges to).
      final oldSlotId = appointment['slotId'] as String?;
      DocumentReference<Map<String, dynamic>>? oldSlotRef;
      var oldSlotBooked = false;
      if (oldSlotId != null) {
        oldSlotRef = _firestore.collection('slots').doc(oldSlotId);
        final oldSlotSnapshot = await transaction.get(oldSlotRef);
        oldSlotBooked = oldSlotSnapshot.exists &&
            oldSlotSnapshot.data()!['isBooked'] == true;
      }
      if (!oldSlotBooked) {
        throw const SlotUnavailableException();
      }

      // --- writes ---
      committedAppointment = appointment;
      committedNewSlot = newSlot;
      transaction.update(newSlotRef, {'isBooked': true});
      // Re-point the appointment at the new slot; start/end are copied from
      // the new slot doc (same denormalization as bookSlot). Status stays
      // 'scheduled' — rescheduling is not a lifecycle change.
      transaction.update(appointmentRef, {
        'slotId': newSlotId,
        'startTime': newSlot['startTime'],
        'endTime': newSlot['endTime'],
      });
      transaction.update(oldSlotRef!, {'isBooked': false});
    });

    final appointment = committedAppointment!;
    final newSlot = committedNewSlot!;
    return Appointment(
      id: appointmentId,
      patientId: appointment['patientId'] as String,
      doctorId: appointment['doctorId'] as String,
      slotId: newSlotId,
      // Timestamps are UTC instants (see the TimeSlot contract); toDate()
      // yields local, so normalize.
      startTime: (newSlot['startTime'] as Timestamp).toDate().toUtc(),
      endTime: (newSlot['endTime'] as Timestamp).toDate().toUtc(),
      status: AppointmentStatus.scheduled,
      createdAt: (appointment['createdAt'] as Timestamp).toDate().toUtc(),
    );
  }
}

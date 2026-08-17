import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/entities/appointment.dart';

/// Thrown when an appointment is already cancelled — cancelling again would
/// be a no-op that double-releases the slot.
///
/// Deliberately NOT a Firebase exception: this is our business rule, so the
/// repository catches it BEFORE the Firebase error mapper and returns
/// [AppointmentAlreadyCancelledError]. A *missing* appointment — and an
/// appointment that belongs to someone else (treated as non-existent so the
/// check leaks nothing) — instead raises a `not-found` FirebaseException
/// (same trick as FirestoreDoctorsDataSource) so the existing mapper yields
/// [NotFoundError].
class AppointmentAlreadyCancelledException implements Exception {
  const AppointmentAlreadyCancelledException();
}

/// The only place in the appointments feature that touches the Firestore
/// SDK for writes.
///
/// [getAppointments] reads the `appointments` collection (schema written by
/// Task 12's booking transaction) filtered by patient, and sorts in memory
/// — a `where` + `orderBy` query would need a composite index, and a
/// patient's appointment count is tiny. Index work is Task 15's job.
///
/// [cancelAppointment] runs ONE transaction over the appointment document
/// (the OWNERSHIP RECORD), mirroring the booking transaction:
///
///   read    `appointments/<id>`
///   verify  exists, owned by the caller, still scheduled
///   write   `appointments/<id> = {status: 'cancelled', cancelledAt: ...}`
///           `slots/<slotId>.isBooked = false`   (if the slot still exists)
///
/// The slot document is only the LOCK here — flipping it back to false is
/// what makes the slot bookable again. If the slot doc is somehow missing
/// (data inconsistency), the appointment still gets cancelled: the slot is
/// not the record of truth, and a stray `isBooked: true` on a vanished slot
/// is harmless.
class FirestoreAppointmentsDataSource {
  FirestoreAppointmentsDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<Appointment>> getAppointments(String patientId) async {
    final snapshot = await _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .get();
    final appointments = snapshot.docs.map(_toAppointment).toList()
      // Sort in Dart rather than orderBy (no composite index needed).
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return appointments;
  }

  Future<Appointment> cancelAppointment({
    required String patientId,
    required String appointmentId,
  }) async {
    final appointmentRef =
        _firestore.collection('appointments').doc(appointmentId);

    // Captured inside the transaction callback so the returned entity is
    // built from the values the transaction actually committed with.
    Map<String, dynamic>? committedAppointment;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(appointmentRef);
      if (!snapshot.exists) {
        // Match the doctors/booking data source pattern: raise the
        // SDK-shaped 'not-found' exception so the mapper yields
        // NotFoundError.
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Appointment $appointmentId was not found.',
        );
      }
      final appointment = snapshot.data() as Map<String, dynamic>;
      // Ownership check: an appointment that isn't the caller's is treated
      // as non-existent (standard practice — no info leak, and it reuses
      // the existing NotFoundError path).
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

      committedAppointment = appointment;

      // Firestore transactions require ALL reads before ANY writes, so the
      // slot read happens up front; whether it exists decides the update
      // below.
      final slotId = appointment['slotId'] as String?;
      DocumentReference<Map<String, dynamic>>? slotRef;
      var slotExists = false;
      if (slotId != null) {
        slotRef = _firestore.collection('slots').doc(slotId);
        slotExists = (await transaction.get(slotRef)).exists;
      }

      transaction.update(appointmentRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      // Free the slot so it's bookable again — if it still exists. The
      // appointment still gets cancelled when the slot doc is gone (it's
      // only a lock, not the record of truth).
      if (slotExists) {
        transaction.update(slotRef!, {'isBooked': false});
      }
    });

    final appointment = committedAppointment!;
    return Appointment(
      id: appointmentId,
      patientId: appointment['patientId'] as String,
      doctorId: appointment['doctorId'] as String,
      slotId: appointment['slotId'] as String,
      // Timestamps are UTC instants (see the TimeSlot contract); toDate()
      // yields local, so normalize.
      startTime: (appointment['startTime'] as Timestamp).toDate().toUtc(),
      endTime: (appointment['endTime'] as Timestamp).toDate().toUtc(),
      status: AppointmentStatus.cancelled,
      createdAt: (appointment['createdAt'] as Timestamp).toDate().toUtc(),
    );
  }

  Appointment _toAppointment(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      patientId: data['patientId'] as String,
      doctorId: data['doctorId'] as String,
      slotId: data['slotId'] as String,
      startTime: (data['startTime'] as Timestamp).toDate().toUtc(),
      endTime: (data['endTime'] as Timestamp).toDate().toUtc(),
      status: _statusFrom(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp).toDate().toUtc(),
      cancelledAt: data['cancelledAt'] == null
          ? null
          : (data['cancelledAt'] as Timestamp).toDate().toUtc(),
    );
  }

  AppointmentStatus _statusFrom(String? raw) => switch (raw) {
        'scheduled' => AppointmentStatus.scheduled,
        'completed' => AppointmentStatus.completed,
        _ => AppointmentStatus.cancelled,
      };
}

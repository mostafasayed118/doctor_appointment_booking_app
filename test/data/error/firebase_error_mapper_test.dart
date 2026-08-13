import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/error/app_error.dart';
import 'package:doctor_appointment_booking_app/data/error/firebase_error_mapper.dart';

void main() {
  const mapper = FirebaseErrorMapper();

  group('FirebaseErrorMapper', () {
    group('FirebaseAuthException', () {
      test('maps to AuthError', () {
        final error = auth.FirebaseAuthException(
          code: 'invalid-credential',
          message: 'The supplied auth credential is incorrect.',
        );

        final result = mapper.map(error);

        expect(result, isA<AuthError>());
        expect(result.code, 'auth_error');
        expect(result.message, 'The supplied auth credential is incorrect.');
      });

      test('falls back to the code when message is null', () {
        final error = auth.FirebaseAuthException(code: 'weak-password');

        final result = mapper.map(error);

        expect(result, isA<AuthError>());
        expect(result.message, 'weak-password');
      });
    });

    group('FirebaseException', () {
      test('maps unavailable to NetworkError', () {
        final error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
          message: 'The service is currently unavailable.',
        );

        final result = mapper.map(error);

        expect(result, isA<NetworkError>());
        expect(result.code, 'network_error');
      });

      test('maps deadline-exceeded to NetworkError', () {
        final error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'deadline-exceeded',
        );

        final result = mapper.map(error);

        expect(result, isA<NetworkError>());
      });

      test('maps not-found to NotFoundError', () {
        final error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'No document found.',
        );

        final result = mapper.map(error);

        expect(result, isA<NotFoundError>());
        expect(result.code, 'not_found');
      });

      test('maps permission-denied to ServerError', () {
        final error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );

        final result = mapper.map(error);

        expect(result, isA<ServerError>());
        expect(result.code, 'server_error');
      });

      test('maps unknown Firestore codes to ServerError', () {
        final error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'aborted',
          message: 'The operation was aborted.',
        );

        final result = mapper.map(error);

        expect(result, isA<ServerError>());
        expect(result.message, 'The operation was aborted.');
      });
    });

    group('unknown errors', () {
      test('maps anything else to UnexpectedError', () {
        final result = mapper.map(StateError('boom'));

        expect(result, isA<UnexpectedError>());
        expect(result.code, 'unexpected_error');
        expect(result.message, contains('boom'));
      });
    });
  });
}
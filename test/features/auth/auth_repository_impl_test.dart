import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/error/app_error.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/data/error/firebase_error_mapper.dart';
import 'package:doctor_appointment_booking_app/features/auth/data/auth_data_source.dart';
import 'package:doctor_appointment_booking_app/features/auth/data/auth_repository_impl.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';

class MockAuthDataSource extends Mock implements AuthDataSource {}

void main() {
  const user = AuthUser(uid: 'u1', email: 'ana@example.com');
  const mapper = FirebaseErrorMapper();

  late MockAuthDataSource dataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    dataSource = MockAuthDataSource();
    repository = AuthRepositoryImpl(dataSource: dataSource, mapper: mapper);
  });

  group('signIn', () {
    test('returns Success with the signed-in user', () async {
      when(
        () => dataSource.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user);

      final result = await repository.signIn(
        email: 'ana@example.com',
        password: 'secret123',
      );

      expect(result, isA<Success<AuthUser>>());
      expect((result as Success<AuthUser>).value, user);
    });

    test('maps FirebaseAuthException to Failure<AuthError>', () async {
      when(
        () => dataSource.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        auth.FirebaseAuthException(
          code: 'invalid-credential',
          message: 'The supplied auth credential is incorrect.',
        ),
      );

      final result = await repository.signIn(
        email: 'ana@example.com',
        password: 'wrong-password',
      );

      expect(result, isA<Failure<AuthUser>>());
      final error = (result as Failure<AuthUser>).error;
      expect(error, isA<AuthError>());
      expect(error.message, 'The supplied auth credential is incorrect.');
    });

    test('maps unexpected errors to Failure<UnexpectedError>', () async {
      when(
        () => dataSource.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(StateError('boom'));

      final result = await repository.signIn(
        email: 'ana@example.com',
        password: 'secret123',
      );

      expect((result as Failure<AuthUser>).error, isA<UnexpectedError>());
    });
  });

  group('signUp', () {
    test('returns Success with the created user', () async {
      when(
        () => dataSource.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => user);

      final result = await repository.signUp(
        email: 'ana@example.com',
        password: 'secret123',
        displayName: 'Ana',
      );

      expect(result, isA<Success<AuthUser>>());
      expect((result as Success<AuthUser>).value, user);
    });

    test('maps FirebaseAuthException to Failure<AuthError>', () async {
      when(
        () => dataSource.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenThrow(auth.FirebaseAuthException(code: 'email-already-in-use'));

      final result = await repository.signUp(
        email: 'taken@example.com',
        password: 'secret123',
      );

      expect((result as Failure<AuthUser>).error, isA<AuthError>());
    });
  });

  group('signOut', () {
    test('returns Success when the data source signs out', () async {
      when(() => dataSource.signOut()).thenAnswer((_) async {});

      final result = await repository.signOut();

      expect(result, isA<Success<void>>());
    });

    test('maps failures to Failure<AuthError>', () async {
      when(() => dataSource.signOut())
          .thenThrow(auth.FirebaseAuthException(code: 'network-request-failed'));

      final result = await repository.signOut();

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).error, isA<AuthError>());
    });
  });

  group('observeAuthState', () {
    test('forwards events from the data source stream', () async {
      final controller = StreamController<AuthUser?>();
      addTearDown(controller.close);
      when(() => dataSource.observeAuthState())
          .thenAnswer((_) => controller.stream);

      final received = <AuthUser?>[];
      final subscription =
          repository.observeAuthState().listen(received.add);
      addTearDown(subscription.cancel);

      controller.add(user);
      controller.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(received, [user, null]);
    });
  });
}

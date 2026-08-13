import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// core.AuthError is the AppError subtype; the unqualified AuthError is the
// AuthState variant from auth_state.dart — the import below keeps them apart.
import 'package:doctor_appointment_booking_app/core/error/app_error.dart'
    as core;
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_repository.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_in.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_out.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_up.dart';
import 'package:doctor_appointment_booking_app/features/auth/presentation/auth_cubit.dart';
import 'package:doctor_appointment_booking_app/features/auth/presentation/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  const user = AuthUser(uid: 'u1', email: 'ana@example.com', displayName: 'Ana');

  late MockAuthRepository repository;
  late StreamController<AuthUser?> authStateController;

  setUp(() {
    repository = MockAuthRepository();
    authStateController = StreamController<AuthUser?>.broadcast();
    when(() => repository.observeAuthState())
        .thenAnswer((_) => authStateController.stream);
  });

  tearDown(() async {
    await authStateController.close();
  });

  AuthCubit buildCubit() => AuthCubit(
        signIn: SignIn(repository),
        signUp: SignUp(repository),
        signOut: SignOut(repository),
        repository: repository,
      );

  group('observeAuthState', () {
    blocTest<AuthCubit, AuthState>(
      'emits Unauthenticated when no user is signed in',
      build: buildCubit,
      act: (cubit) => authStateController.add(null),
      expect: () => const [Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits Authenticated when a user is signed in',
      build: buildCubit,
      act: (cubit) => authStateController.add(user),
      expect: () => [Authenticated(user)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError when the auth state stream errors',
      build: buildCubit,
      act: (cubit) => authStateController.addError(const core.NetworkError()),
      expect: () => const [AuthError(core.NetworkError())],
    );
  });

  group('signIn', () {
    blocTest<AuthCubit, AuthState>(
      'emits Authenticated on success',
      build: buildCubit,
      setUp: () => when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Success(user)),
      act: (cubit) => cubit.signIn(email: 'ana@example.com', password: 'secret123'),
      expect: () => [const AuthLoading(), Authenticated(user)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError on failure',
      build: buildCubit,
      setUp: () => when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Failure(core.NetworkError())),
      act: (cubit) => cubit.signIn(email: 'ana@example.com', password: 'wrong'),
      expect: () => const [AuthLoading(), AuthError(core.NetworkError())],
    );
  });

  group('signUp', () {
    blocTest<AuthCubit, AuthState>(
      'emits Authenticated on success',
      build: buildCubit,
      setUp: () => when(
        () => repository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => const Success(user)),
      act: (cubit) => cubit.signUp(
        email: 'ana@example.com',
        password: 'secret123',
        displayName: 'Ana',
      ),
      expect: () => [const AuthLoading(), Authenticated(user)],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError when the email is already in use',
      build: buildCubit,
      setUp: () => when(
        () => repository.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        ),
      ).thenAnswer((_) async => const Failure(core.AuthError())),
      act: (cubit) => cubit.signUp(
        email: 'taken@example.com',
        password: 'secret123',
      ),
      expect: () => const [AuthLoading(), AuthError(core.AuthError())],
    );
  });

  group('reset', () {
    blocTest<AuthCubit, AuthState>(
      'recovers to the sign-in form after a failed sign-in',
      build: buildCubit,
      setUp: () => when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Failure(core.AuthError())),
      act: (cubit) async {
        await cubit.signIn(email: 'ana@example.com', password: 'wrong');
        cubit.reset();
      },
      expect: () => const [
        AuthLoading(),
        AuthError(core.AuthError()),
        Unauthenticated(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'recovers to Authenticated when a user is signed in',
      build: buildCubit,
      setUp: () => when(
        () => repository.signOut(),
      ).thenAnswer((_) async => const Failure(core.AuthError())),
      act: (cubit) async {
        authStateController.add(user);
        // Let the stream deliver before the failing action runs.
        await Future<void>.delayed(Duration.zero);
        await cubit.signOut();
        cubit.reset();
      },
      expect: () => const [
        Authenticated(user),
        AuthLoading(),
        AuthError(core.AuthError()),
        Authenticated(user),
      ],
    );
  });

  group('signOut', () {
    blocTest<AuthCubit, AuthState>(
      'emits Unauthenticated via the stream after a successful sign-out',
      build: buildCubit,
      setUp: () => when(
        () => repository.signOut(),
      ).thenAnswer((_) async => const Success<void>(null)),
      act: (cubit) async {
        // Sign-out success is reported by the auth state stream, not the
        // returned value — the cubit waits for Firebase to emit null.
        unawaited(cubit.signOut());
        authStateController.add(null);
      },
      expect: () => const [AuthLoading(), Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'emits AuthError when sign-out fails',
      build: buildCubit,
      setUp: () => when(
        () => repository.signOut(),
      ).thenAnswer((_) async => const Failure(core.AuthError())),
      act: (cubit) => cubit.signOut(),
      expect: () => const [AuthLoading(), AuthError(core.AuthError())],
    );
  });
}

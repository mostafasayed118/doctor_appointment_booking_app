import 'package:doctor_appointment_booking_app/app.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_in.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_out.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_up.dart';
import 'package:doctor_appointment_booking_app/features/auth/presentation/auth_cubit.dart';
import 'package:doctor_appointment_booking_app/shared/routing/router.dart';

import 'fake_auth_repository.dart';

/// Builds the app shell over a router driven by [repository], so widget
/// tests exercise the real auth-guard navigation without Firebase.
///
/// Returns the pieces the test needs to drive the flow: the widget to pump,
/// the real [AuthCubit] (sign in/out via cubit calls or taps), and the fake
/// repository (simulate stream-driven auth state with [FakeAuthRepository.emitAuthState]).
///
/// Callers must still `setupLocator()` first — the app shell resolves
/// `LocaleService` from GetIt during build.
({DoctorAppointmentApp app, AuthCubit cubit, FakeAuthRepository repository})
    buildTestApp({
  required FakeAuthRepository repository,
  AuthUser? initialUser,
  String initialLocation = '/',
}) {
  final cubit = AuthCubit(
    signIn: SignIn(repository),
    signUp: SignUp(repository),
    signOut: SignOut(repository),
    repository: repository,
  );
  // Emitted AFTER the cubit subscribed, so it starts in Authenticated —
  // exactly how Firebase reports an existing session at boot.
  if (initialUser != null) {
    repository.emitAuthState(initialUser);
  }
  return (
    app: DoctorAppointmentApp(
      router: buildAppRouter(cubit, initialLocation: initialLocation),
    ),
    cubit: cubit,
    repository: repository,
  );
}

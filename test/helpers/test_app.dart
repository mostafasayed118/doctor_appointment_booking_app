import 'package:doctor_appointment_booking_app/app.dart';
import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/di/locator.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_user.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_in.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_out.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_up.dart';
import 'package:doctor_appointment_booking_app/features/auth/presentation/auth_cubit.dart';
import 'package:doctor_appointment_booking_app/features/booking/domain/booking_repository.dart';
import 'package:doctor_appointment_booking_app/features/booking/domain/slots_repository.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/doctors_repository.dart';
import 'package:doctor_appointment_booking_app/shared/routing/router.dart';
import 'package:doctor_appointment_booking_app/core/entities/time_slot.dart';

import 'fake_auth_repository.dart';
import 'fake_booking_repository.dart';
import 'fake_doctors_repository.dart';
import 'fake_slots_repository.dart';

/// Builds the app shell over a router driven by [repository], so widget
/// tests exercise the real auth-guard navigation without Firebase.
///
/// Returns the pieces the test needs to drive the flow: the widget to pump,
/// the real [AuthCubit] (sign in/out via cubit calls or taps), and the fake
/// repository (simulate stream-driven auth state with [FakeAuthRepository.emitAuthState]).
///
/// Callers must still `setupLocator()` first — the app shell resolves
/// `LocaleService` from GetIt during build.
///
/// The real doctors repository constructs `FirebaseFirestore.instance`
/// (a platform-channel hang in unit tests), so the harness overrides the
/// locator registration with [doctors]' fake. Router tests can then
/// navigate to /doctors with the real cubit chain over fake data.
({DoctorAppointmentApp app, AuthCubit cubit, FakeAuthRepository repository})
buildTestApp({
  required FakeAuthRepository repository,
  AuthUser? initialUser,
  String initialLocation = '/',
  List<Doctor> doctors = const [],
  Map<String, List<TimeSlot>> slotsByDoctor = const {},
}) {
  // GetIt 9: overriding an existing registration is gated by an instance
  // flag rather than a per-call parameter (allowReassignment: true).
  sl.allowReassignment = true;
  sl.registerSingleton<DoctorsRepository>(
    FakeDoctorsRepository(doctors: doctors),
  );
  sl.registerSingleton<SlotsRepository>(
    FakeSlotsRepository(slotsByDoctor: slotsByDoctor),
  );
  sl.registerSingleton<BookingRepository>(FakeBookingRepository());

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
  // Same seam for slots: the booking screen's cubit chain runs over the
  // fake so router tests can reach /doctors/:id/book without a platform
  // channel hang.
  return (
    app: DoctorAppointmentApp(
      router: buildAppRouter(cubit, initialLocation: initialLocation),
    ),
    cubit: cubit,
    repository: repository,
  );
}

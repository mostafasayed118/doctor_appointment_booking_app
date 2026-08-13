import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// Note: resolving AuthRepository is deliberately NOT tested here — its
// construction touches FirebaseAuth.instance, which blocks on a platform
// channel that never answers in unit tests. Registration is verified via
// isRegistered (which does not construct).
import 'package:doctor_appointment_booking_app/di/locator.dart';
import 'package:doctor_appointment_booking_app/features/auth/data/auth_data_source.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/auth_repository.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_in.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_out.dart';
import 'package:doctor_appointment_booking_app/features/auth/domain/use_cases/sign_up.dart';
import 'package:doctor_appointment_booking_app/features/auth/presentation/auth_cubit.dart';
import 'package:doctor_appointment_booking_app/features/doctors/data/firestore_doctors_data_source.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/doctors_repository.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/use_cases/get_doctor.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/use_cases/get_doctors.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/doctor_profile_cubit.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/doctors_list_cubit.dart';
import 'package:doctor_appointment_booking_app/shared/services/locale_service.dart';

void main() {
  tearDown(resetLocator);

  test('setupLocator registers the core and auth services', () {
    setupLocator();

    expect(sl.isRegistered<LocaleService>(), isTrue);
    expect(sl.isRegistered<AuthDataSource>(), isTrue);
    expect(sl.isRegistered<AuthRepository>(), isTrue);
    expect(sl.isRegistered<SignIn>(), isTrue);
    expect(sl.isRegistered<SignUp>(), isTrue);
    expect(sl.isRegistered<SignOut>(), isTrue);
    expect(sl.isRegistered<AuthCubit>(), isTrue);
    // The router is registered lazily and built from the AuthCubit
    // singleton (guard state source + refreshListenable).
    expect(sl.isRegistered<GoRouter>(), isTrue);

    // Doctors chain: data source → repository → use cases → screen-scoped
    // cubits (factories, so each navigation gets a fresh instance).
    expect(sl.isRegistered<FirestoreDoctorsDataSource>(), isTrue);
    expect(sl.isRegistered<DoctorsRepository>(), isTrue);
    expect(sl.isRegistered<GetDoctors>(), isTrue);
    expect(sl.isRegistered<GetDoctor>(), isTrue);
    expect(sl.isRegistered<DoctorsListCubit>(), isTrue);
    expect(sl.isRegistered<DoctorProfileCubit>(), isTrue);
  });

  test('resetting the locator clears all registrations', () async {
    setupLocator();
    expect(sl.isRegistered<AuthRepository>(), isTrue);

    await resetLocator();

    expect(sl.isRegistered<AuthRepository>(), isFalse);
  });
}

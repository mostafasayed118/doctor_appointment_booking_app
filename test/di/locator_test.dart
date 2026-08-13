import 'package:flutter_test/flutter_test.dart';

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
  });

  test('resetting the locator clears all registrations', () async {
    setupLocator();
    expect(sl.isRegistered<AuthRepository>(), isTrue);

    await resetLocator();

    expect(sl.isRegistered<AuthRepository>(), isFalse);
  });
}

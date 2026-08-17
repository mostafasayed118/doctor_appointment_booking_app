import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_data_source.dart';
import '../features/auth/data/auth_repository_impl.dart';
import '../features/auth/domain/auth_repository.dart';
import '../features/auth/domain/use_cases/sign_in.dart';
import '../features/auth/domain/use_cases/sign_out.dart';
import '../features/auth/domain/use_cases/sign_up.dart';
import '../features/auth/presentation/auth_cubit.dart';
import '../features/booking/data/firestore_slots_data_source.dart';
import '../features/booking/data/slots_repository_impl.dart';
import '../features/booking/domain/slots_repository.dart';
import '../features/booking/domain/use_cases/get_slots.dart';
import '../features/booking/presentation/slot_selection_cubit.dart';
import '../features/doctors/data/doctors_repository_impl.dart';
import '../features/doctors/data/firestore_doctors_data_source.dart';
import '../features/doctors/domain/doctors_repository.dart';
import '../features/doctors/domain/use_cases/get_doctor.dart';
import '../features/doctors/domain/use_cases/get_doctors.dart';
import '../features/doctors/presentation/doctor_profile_cubit.dart';
import '../features/doctors/presentation/doctors_list_cubit.dart';
import '../shared/routing/router.dart';
import '../shared/services/locale_service.dart';

/// Global service locator.
///
/// Registered once in [setupLocator] (called from `main` before `runApp`)
/// and reset between tests via [resetLocator].
///
/// Registration philosophy:
/// - Repositories/data sources are long-lived → `registerLazySingleton`.
/// - [AuthCubit] is deliberately a singleton, unlike screen-scoped Cubits:
///   auth identity is APP-global (Task 8's route guard reads it), so there
///   is exactly one source of truth for "who am I". Screen-scoped Cubits
///   will use `registerFactory` once GoRouter owns them per navigation.
///
/// This file is the only place that knows all the wiring; feature code
/// should only ever reach for `sl<T>()`.
final GetIt sl = GetIt.instance;

void setupLocator() {
  sl.registerLazySingleton<LocaleService>(() => LocaleService());

  sl.registerLazySingleton<AuthDataSource>(() => AuthDataSource());
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl<AuthDataSource>()),
  );
  sl.registerLazySingleton<SignIn>(() => SignIn(sl<AuthRepository>()));
  sl.registerLazySingleton<SignUp>(() => SignUp(sl<AuthRepository>()));
  sl.registerLazySingleton<SignOut>(() => SignOut(sl<AuthRepository>()));
  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      signIn: sl<SignIn>(),
      signUp: sl<SignUp>(),
      signOut: sl<SignOut>(),
      repository: sl<AuthRepository>(),
    ),
  );
  sl.registerLazySingleton<FirestoreDoctorsDataSource>(
    () => FirestoreDoctorsDataSource(),
  );
  sl.registerLazySingleton<DoctorsRepository>(
    () => DoctorsRepositoryImpl(dataSource: sl<FirestoreDoctorsDataSource>()),
  );
  sl.registerLazySingleton<GetDoctors>(() => GetDoctors(sl<DoctorsRepository>()));
  sl.registerLazySingleton<GetDoctor>(() => GetDoctor(sl<DoctorsRepository>()));

  // Screen-scoped Cubits: a fresh instance per navigation (the router's
  // BlocProvider(create:) closes them on unmount), unlike the app-global
  // AuthCubit singleton above.
  sl.registerFactory<DoctorsListCubit>(
    () => DoctorsListCubit(getDoctors: sl<GetDoctors>()),
  );
  sl.registerFactory<DoctorProfileCubit>(
    () => DoctorProfileCubit(getDoctor: sl<GetDoctor>()),
  );

  sl.registerLazySingleton<FirestoreSlotsDataSource>(
    () => FirestoreSlotsDataSource(),
  );
  sl.registerLazySingleton<SlotsRepository>(
    () => SlotsRepositoryImpl(dataSource: sl<FirestoreSlotsDataSource>()),
  );
  sl.registerLazySingleton<GetSlots>(() => GetSlots(sl<SlotsRepository>()));
  sl.registerFactory<SlotSelectionCubit>(
    () => SlotSelectionCubit(getSlots: sl<GetSlots>()),
  );

  // Router depends on the AuthCubit singleton: the cubit is both the
  // redirect's state source and GoRouter's refreshListenable.
  sl.registerLazySingleton<GoRouter>(() => buildAppRouter(sl<AuthCubit>()));
}

/// Tears down the container. Used by tests so registrations don't leak
/// between test files.
///
/// `GetIt.reset()` is asynchronous (it returns a `Future<void>`), so this
/// must be awaited by callers.
Future<void> resetLocator() async {
  await sl.reset();
}

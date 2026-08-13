import 'package:get_it/get_it.dart';

/// Global service locator.
///
/// Registered once in [setupLocator] (called from `main` before `runApp`)
/// and reset between tests via [resetLocator].
///
/// Registration philosophy (used from Task 7 onward):
/// - Repositories/data sources are long-lived → `registerLazySingleton`.
/// - Screen-scoped Cubits need a fresh instance per screen →
///   `registerFactory` (GoRouter constructs them per navigation).
///
/// This file is the only place that knows all the wiring; feature code
/// should only ever reach for `sl<T>()`.
final GetIt sl = GetIt.instance;

/// Registers a placeholder service so the DI wiring can be tested before
/// real feature registrations land in later tasks.
///
/// This is scaffolding only — it is removed in Task 7 when the auth
/// feature registers its first real dependencies.
class PlaceholderService {
  const PlaceholderService();
}

void setupLocator() {
  sl.registerLazySingleton<PlaceholderService>(
    () => const PlaceholderService(),
  );
}

/// Tears down the container. Used by tests so registrations don't leak
/// between test files.
///
/// `GetIt.reset()` is asynchronous (it returns a `Future<void>`), so this
/// must be awaited by callers.
Future<void> resetLocator() async {
  await sl.reset();
}

import 'app_error.dart';

/// The result of a repository operation.
///
/// Repositories return a [Result] instead of throwing, so failures are
/// explicit return values that callers must handle. This keeps Firebase
/// exceptions inside the data layer — Cubits and widgets only ever see
/// typed [AppError]s.
///
/// [Result] is a sealed class: the compiler knows the only two possible
/// subtypes are [Success] and [Failure], so exhaustive `switch`/pattern
/// matching is enforced at compile time.
sealed class Result<T> {
  const Result();

  /// Collapses the result into a single value by handling both cases.
  ///
  /// Example:
  /// ```dart
  /// final message = result.fold(
  ///   onSuccess: (doctors) => 'Loaded ${doctors.length} doctors',
  ///   onFailure: (error) => error.message,
  /// );
  /// ```
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppError error) onFailure,
  }) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Failure<T>(:final error) => onFailure(error),
    };
  }
}

/// A successful result carrying a [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// A failed result carrying a typed [error].
final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppError error;
}
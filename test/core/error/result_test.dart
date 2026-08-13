import 'package:flutter_test/flutter_test.dart';

import 'package:doctor_appointment_booking_app/core/error/app_error.dart';
import 'package:doctor_appointment_booking_app/core/error/result.dart';

void main() {
  group('Result<T>', () {
    test('Success carries the value', () {
      const result = Success<int>(42);

      expect(result.value, 42);
    });

    test('Failure carries the error', () {
      const error = NetworkError();
      const result = Failure<int>(error);

      expect(result.error, error);
    });

    test('fold calls onSuccess for a Success', () {
      const result = Success<int>(42);

      final output = result.fold(
        onSuccess: (value) => 'value: $value',
        onFailure: (error) => 'error: ${error.code}',
      );

      expect(output, 'value: 42');
    });

    test('fold calls onFailure for a Failure', () {
      const result = Failure<int>(NetworkError());

      final output = result.fold(
        onSuccess: (value) => 'value: $value',
        onFailure: (error) => 'error: ${error.code}',
      );

      expect(output, 'error: network_error');
    });

    test('Success and Failure are distinct subtypes', () {
      const success = Success<int>(1);
      const failure = Failure<int>(NetworkError());

      expect(success, isA<Result<int>>());
      expect(failure, isA<Result<int>>());
      expect(success, isNot(isA<Failure<int>>()));
      expect(failure, isNot(isA<Success<int>>()));
    });
  });
}
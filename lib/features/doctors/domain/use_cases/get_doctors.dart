import '../../../../core/entities/doctor.dart';
import '../../../../core/error/result.dart';
import '../doctors_repository.dart';

/// Loads every doctor for the browse list.
class GetDoctors {
  const GetDoctors(this._repository);

  final DoctorsRepository _repository;

  Future<Result<List<Doctor>>> call() => _repository.getDoctors();
}

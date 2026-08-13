import '../../../../core/entities/doctor.dart';
import '../../../../core/error/result.dart';
import '../doctors_repository.dart';

/// Loads a single doctor for the profile page.
class GetDoctor {
  const GetDoctor(this._repository);

  final DoctorsRepository _repository;

  Future<Result<Doctor>> call(String id) => _repository.getDoctor(id);
}

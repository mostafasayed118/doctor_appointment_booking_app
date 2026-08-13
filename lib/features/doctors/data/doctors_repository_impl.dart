import '../../../core/entities/doctor.dart';
import '../../../core/error/result.dart';
import '../../../data/error/firebase_error_mapper.dart';
import '../domain/doctors_repository.dart';
import 'firestore_doctors_data_source.dart';

/// Production [DoctorsRepository]: delegates to [FirestoreDoctorsDataSource]
/// and maps every thrown SDK exception to a typed [AppError] at THIS
/// boundary. Cubits and widgets never see a Firebase exception — only the
/// [Result] contract from core.
class DoctorsRepositoryImpl implements DoctorsRepository {
  DoctorsRepositoryImpl({
    required this._dataSource,
    this._mapper = const FirebaseErrorMapper(),
  });

  final FirestoreDoctorsDataSource _dataSource;
  final FirebaseErrorMapper _mapper;

  @override
  Future<Result<List<Doctor>>> getDoctors() async {
    try {
      return Success(await _dataSource.fetchDoctors());
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }

  @override
  Future<Result<Doctor>> getDoctor(String id) async {
    try {
      return Success(await _dataSource.fetchDoctor(id));
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }
}

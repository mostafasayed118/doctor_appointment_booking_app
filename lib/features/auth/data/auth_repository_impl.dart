import '../../../core/error/result.dart';
import '../../../data/error/firebase_error_mapper.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'auth_data_source.dart';

/// Production [AuthRepository]: delegates to [AuthDataSource] and maps every
/// thrown SDK exception to a typed [AppError] at THIS boundary.
///
/// Cubits and widgets never see a Firebase exception — only the [Result]
/// contract from core.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._dataSource,
    this._mapper = const FirebaseErrorMapper(),
  });

  final AuthDataSource _dataSource;
  final FirebaseErrorMapper _mapper;

  @override
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signIn(email: email, password: password);
      return Success(user);
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }

  @override
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await _dataSource.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      return Success(user);
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Success<void>(null);
    } catch (error) {
      return Failure(_mapper.map(error));
    }
  }

  @override
  Stream<AuthUser?> observeAuthState() => _dataSource.observeAuthState();
}

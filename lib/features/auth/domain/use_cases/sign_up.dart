import '../../../../core/error/result.dart';
import '../auth_repository.dart';
import '../auth_user.dart';

/// Creates a new account with email/password and signs the user in.
class SignUp {
  const SignUp(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}

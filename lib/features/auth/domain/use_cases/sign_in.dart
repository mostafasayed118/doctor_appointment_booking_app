import '../../../../core/error/result.dart';
import '../auth_repository.dart';
import '../auth_user.dart';

/// Signs a user in with email/password.
///
/// Thin by design: it names the intent for the presentation layer and keeps
/// the repository behind the domain contract. If a use case ever grows real
/// logic (validation, orchestration), this is where it lives.
class SignIn {
  const SignIn(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}

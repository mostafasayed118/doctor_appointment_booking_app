import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

// core.* is the AppError family (incl. the AuthError AppError subtype);
// the unqualified AuthError is the AuthState variant from auth_state.dart.
import '../../../core/error/app_error.dart' as core;
import '../../../core/error/result.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/use_cases/sign_in.dart';
import '../domain/use_cases/sign_out.dart';
import '../domain/use_cases/sign_up.dart';
import 'auth_state.dart';

/// Owns the auth screen state.
///
/// Two inputs drive [AuthState]:
/// 1. The auth state stream (`observeAuthState`) — the source of truth for
///    "who am I". Emits [Authenticated]/[Unauthenticated] automatically.
/// 2. One-shot actions (signIn/signUp/signOut) — emit [AuthLoading], then a
///    terminal state. Sign-out success itself is only confirmed through the
///    stream (Firebase emits null), so [AuthCubit] waits for that event.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this._signIn,
    required this._signUp,
    required this._signOut,
    required this._repository,
  }) : super(const AuthInitial()) {
    _authSubscription = _repository.observeAuthState().listen(
          _onAuthStateChanged,
          onError: _onAuthStateError,
        );
  }

  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final AuthRepository _repository;
  late final StreamSubscription<AuthUser?> _authSubscription;

  void _onAuthStateChanged(AuthUser? user) {
    emit(user == null ? const Unauthenticated() : Authenticated(user));
  }

  void _onAuthStateError(Object error) {
    emit(AuthError(
      error is core.AppError
          ? error
          : core.UnexpectedError(message: error.toString()),
    ));
  }

  Future<void> signIn({required String email, required String password}) {
    return _runAuthAction(() => _signIn(email: email, password: password));
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _runAuthAction(
      () => _signUp(email: email, password: password, displayName: displayName),
    );
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    final result = await _signOut();
    if (result case Failure(:final error)) {
      emit(AuthError(error));
    }
    // On success we deliberately do NOT emit Unauthenticated here: the auth
    // state stream will emit null, keeping a single source of truth.
  }

  Future<void> _runAuthAction(Future<Result<AuthUser>> Function() action) async {
    emit(const AuthLoading());
    final result = await action();
    switch (result) {
      case Success(:final value):
        emit(Authenticated(value));
      case Failure(:final error):
        emit(AuthError(error));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    await super.close();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
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
///
/// Implements [Listenable] via [ChangeNotifier]: bloc 9 dropped the
/// `Listenable` implementation from `BlocBase`, and GoRouter's
/// `refreshListenable` needs it so every state change re-runs the auth
/// guard redirect.
class AuthCubit extends Cubit<AuthState> with ChangeNotifier {
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
    // GoRouter refreshListenable: re-run the auth guard on every state
    // change. Listens to our OWN state stream (not `onChange`) because
    // bloc 9 fires `onChange` BEFORE `_state` is updated — notifying there
    // would make the redirect read the stale previous state.
    _stateSubscription = stream.listen((_) => notifyListeners());
  }

  final SignIn _signIn;
  final SignUp _signUp;
  final SignOut _signOut;
  final AuthRepository _repository;
  late final StreamSubscription<AuthUser?> _authSubscription;
  late final StreamSubscription<AuthState> _stateSubscription;

  /// Last user reported by the auth state stream — what [reset] returns to
  /// when clearing an error, so it reflects reality (not hardcoded state).
  AuthUser? _currentUser;

  void _onAuthStateChanged(AuthUser? user) {
    _currentUser = user;
    emit(user == null ? const Unauthenticated() : Authenticated(user));
  }

  /// Dismisses an error state and returns to the last known auth reality
  /// ([Authenticated] or [Unauthenticated]). Lets a failed sign-in recover
  /// back to the form without reloading the app.
  void reset() {
    final user = _currentUser;
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
    await _stateSubscription.cancel();
    await super.close();
    dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../di/locator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/app_error_view.dart';
import '../../../shared/components/app_text_field.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import 'login_page.dart';
import 'signed_in_view.dart';

/// New-account screen (email + password + optional display name).
///
/// Mirror of [LoginPage] with one extra field; shares the same global
/// [AuthCubit] so both pages always agree on the auth state.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(AuthCubit cubit) {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _nameError = name.isEmpty ? l10n.enterYourName : null;
      _emailError =
          (email.isEmpty || !email.contains('@')) ? l10n.enterValidEmail : null;
      _passwordError = password.length < 8 ? l10n.passwordTooShort : null;
    });

    if (_nameError == null && _emailError == null && _passwordError == null) {
      cubit.signUp(email: email, password: password, displayName: name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = sl<AuthCubit>();
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.signUp)),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return switch (state) {
              Authenticated(:final user) => SignedInView(
                  user: user,
                  onSignOut: cubit.signOut,
                ),
              AuthError(:final error) => AppErrorView(
                  error: error,
                  onRetry: () => _submit(cubit),
                ),
              AuthLoading() || AuthInitial() || Unauthenticated() =>
                _buildForm(l10n, cubit, state is AuthLoading),
            };
          },
        ),
      ),
    );
  }

  Widget _buildForm(
    AppLocalizations l10n,
    AuthCubit cubit,
    bool loading,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameController,
            label: l10n.fullName,
            errorText: _nameError,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _emailController,
            label: l10n.email,
            hint: 'you@example.com',
            errorText: _emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _passwordController,
            label: l10n.password,
            obscureText: true,
            errorText: _passwordError,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submit(cubit),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: l10n.signUp,
            icon: Icons.person_add,
            loading: loading,
            onPressed: () => _submit(cubit),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const LoginPage()),
            ),
            child: Text(l10n.haveAccountPrompt),
          ),
        ],
      ),
    );
  }
}

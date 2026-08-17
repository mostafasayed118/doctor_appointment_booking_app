import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_button.dart';
import '../../../shared/components/app_error_view.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/app_text_field.dart';
import '../../../shared/components/constrained_content.dart';
import '../../../shared/components/language_toggle_button.dart';
import 'auth_cubit.dart';
import 'auth_state.dart';
import 'signed_in_view.dart';

/// Email/password sign-in screen.
///
/// Reached via the auth guard when signed out (or by users signing in
/// again). The page reflects the GLOBAL auth state (via the shared
/// [AuthCubit]): form when signed out, a signed-in panel when authenticated,
/// full-area error with retry on failure.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(AuthCubit cubit) {
    final l10n = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = (email.isEmpty || !email.contains('@'))
          ? l10n.enterValidEmail
          : null;
      _passwordError = password.length < 8 ? l10n.passwordTooShort : null;
    });

    if (_emailError == null && _passwordError == null) {
      cubit.signIn(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Provided above the route by the router (see buildAppRouter) — the
    // page consumes it from context, never from the locator, so tests can
    // inject a fake cubit.
    final cubit = context.read<AuthCubit>();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signIn),
        actions: const [LanguageToggleButton()],
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return switch (state) {
            Authenticated(:final user) => SignedInView(
              user: user,
              onSignOut: cubit.signOut,
            ),
            AuthError(:final error) => AppErrorView(
              error: error,
              // Retry recovers to the form (fields keep their values)
              // so the user can correct and resubmit — no reload needed.
              onRetry: cubit.reset,
            ),
            AuthLoading() ||
            AuthInitial() ||
            Unauthenticated() => _buildForm(l10n, cubit, state is AuthLoading),
          };
        },
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n, AuthCubit cubit, bool loading) {
    return SingleChildScrollView(
      child: ConstrainedContent(
        // Forms stay a readable width on tablet/desktop instead of
        // stretching edge-to-edge.
        maxWidth: 480,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(cubit),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: l10n.signIn,
                icon: Icons.login,
                loading: loading,
                onPressed: () => _submit(cubit),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/signup'),
                child: Text(l10n.noAccountPrompt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

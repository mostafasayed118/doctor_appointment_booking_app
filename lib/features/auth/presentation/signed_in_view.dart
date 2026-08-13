import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/components/app_button.dart';
import '../domain/auth_user.dart';

/// Shown by both auth pages when a user is authenticated: who is signed in
/// and how to sign out. Shared because auth state is global — whichever page
/// is open reflects the same identity.
class SignedInView extends StatelessWidget {
  const SignedInView({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  final AuthUser user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.signedInAs(user.email),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: l10n.signOut,
              onPressed: onSignOut,
              icon: Icons.logout,
            ),
          ],
        ),
      ),
    );
  }
}

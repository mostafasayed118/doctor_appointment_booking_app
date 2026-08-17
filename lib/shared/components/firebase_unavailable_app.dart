import 'package:flutter/material.dart';

import '../../di/locator.dart';
import '../../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

/// The app shown when Firebase couldn't initialize on this platform.
///
/// `FirebaseBootstrap.init()` fails (gracefully) whenever no platform config
/// exists — e.g. native builds before `google-services.json` /
/// `GoogleService-Info.plist` are added, since only the web app is registered
/// in the Firebase project. Without this guard, the very first router build
/// resolves `AuthCubit` → `FirebaseAuth.instance` and crashes with the
/// `[core/no-app]` exception. This screen keeps the app alive with a clear
/// explanation instead, and touches no Firebase code at all.
class FirebaseUnavailableApp extends StatelessWidget {
  const FirebaseUnavailableApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = sl<LocaleService>();
    return ListenableBuilder(
      listenable: localeService,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        locale: localeService.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // The home subtree needs its own context BELOW MaterialApp so
        // AppLocalizations/Theme resolve — the builder's `context` above is
        // outside the Localizations scope.
        home: Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_outlined, size: 56),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).firebaseUnavailableTitle,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context).firebaseUnavailableBody,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'di/locator.dart';
import 'l10n/app_localizations.dart';
import 'shared/services/locale_service.dart';
import 'shared/theme/app_theme.dart';

/// Root widget of the app.
///
/// Owns the global chrome: theme (Task 5), localization (Task 6), and the
/// GoRouter (Task 8) whose auth guard drives navigation. Listens to
/// [LocaleService] so switching the locale rebuilds `MaterialApp` with the
/// new locale — Flutter then re-resolves localizations and Directionality
/// (AR → RTL automatically).
class DoctorAppointmentApp extends StatelessWidget {
  const DoctorAppointmentApp({super.key, this.router});

  /// Injectable for tests (a router over a fake AuthCubit, since the real
  /// one touches FirebaseAuth which hangs in unit tests). Production uses
  /// the locator-registered router.
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    final localeService = sl<LocaleService>();
    return ListenableBuilder(
      listenable: localeService,
      builder: (context, _) {
        return MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          locale: localeService.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router ?? sl<GoRouter>(),
        );
      },
    );
  }
}

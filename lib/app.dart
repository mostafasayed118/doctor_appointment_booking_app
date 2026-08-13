import 'package:flutter/material.dart';

import 'dev/component_gallery.dart';
import 'di/locator.dart';
import 'l10n/app_localizations.dart';
import 'shared/services/locale_service.dart';
import 'shared/theme/app_theme.dart';

/// Root widget of the app.
///
/// Owns the global chrome: theme (Task 5), localization (Task 6), and
/// shortly the router (Task 8). It listens to [LocaleService] so switching
/// the locale rebuilds `MaterialApp` with the new locale — Flutter then
/// re-resolves localizations and Directionality (AR → RTL automatically).
class DoctorAppointmentApp extends StatelessWidget {
  const DoctorAppointmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeService = sl<LocaleService>();
    return ListenableBuilder(
      listenable: localeService,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          locale: localeService.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Dev home until Task 8 wires the real router. The gallery also
          // hosts the language toggle (Task 6 manual smoke).
          home: const ComponentGallery(),
        );
      },
    );
  }
}

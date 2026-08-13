import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// Holds the app's current [Locale] and notifies listeners on change.
///
/// Deliberately a [ChangeNotifier], not a Cubit: this is app-wide
/// cross-cutting config (like theme mode), not per-screen state. The app
/// shell listens via `ListenableBuilder` and rebuilds `MaterialApp` with the
/// new locale, which makes Flutter re-resolve localizations AND
/// Directionality (`ar` is RTL automatically — no layout code needed).
///
/// Locale choice is intentionally NOT persisted (no shared_preferences in
/// the stack). Default is English so widget tests are deterministic.
class LocaleService extends ChangeNotifier {
  LocaleService({Locale? initialLocale})
      : _locale = initialLocale ?? const Locale('en');

  Locale _locale;

  /// The currently active locale.
  Locale get locale => _locale;

  /// Source of truth for which locales exist — derived from the ARB
  /// catalogs via the generated [AppLocalizations.supportedLocales], so
  /// adding a locale in l10n/ automatically enables it here.
  static bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  /// Switches the locale. Unsupported locales are silently rejected so a
  /// bad input can never leave the app in an untranslated state.
  void setLocale(Locale locale) {
    if (!isSupported(locale) || locale == _locale) return;
    _locale = locale;
    notifyListeners();
  }

  /// Convenience switch between the two supported locales.
  void toggle() {
    setLocale(
      _locale.languageCode == 'en' ? const Locale('ar') : const Locale('en'),
    );
  }
}

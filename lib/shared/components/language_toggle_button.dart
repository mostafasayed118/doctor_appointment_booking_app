import 'package:flutter/material.dart';

import '../../di/locator.dart';
import '../../l10n/app_localizations.dart';
import '../services/locale_service.dart';

/// App-bar language switcher.
///
/// Shows the TARGET language's name in its own script (the localized
/// `switchLanguage` key) and flips the global [LocaleService]. Used by the
/// auth screens (so users can switch to Arabic before signing in) and the
/// gallery home.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: sl<LocaleService>().toggle,
      icon: const Icon(Icons.language),
      label: Text(AppLocalizations.of(context).switchLanguage),
    );
  }
}

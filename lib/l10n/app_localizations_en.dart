// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Doctor Appointment Booking';

  @override
  String get retry => 'Retry';

  @override
  String get switchLanguage => 'العربية';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get fullName => 'Full name';

  @override
  String get enterValidEmail => 'Enter a valid email address';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get noAccountPrompt => 'Don\'t have an account? Sign up';

  @override
  String get haveAccountPrompt => 'Already have an account? Sign in';

  @override
  String get openAuthDemo => 'Open auth demo';

  @override
  String get authUnavailable =>
      'Firebase is not configured yet — sign-in is unavailable.';
}

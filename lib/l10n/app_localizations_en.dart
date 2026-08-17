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
  String get doctorsTitle => 'Doctors';

  @override
  String get searchDoctors => 'Search by name or specialty';

  @override
  String get allSpecialties => 'All';

  @override
  String get noDoctors => 'No doctors yet';

  @override
  String get noDoctorsSubtitle =>
      'Doctors will appear here once they\'re available.';

  @override
  String get noMatches => 'No doctors match';

  @override
  String get noMatchesSubtitle => 'Try a different search or specialty.';

  @override
  String get doctorProfile => 'Doctor profile';

  @override
  String get profileBio => 'About';

  @override
  String get profileClinic => 'Clinic';

  @override
  String get browseDoctors => 'Browse doctors';

  @override
  String get bookAppointment => 'Book appointment';

  @override
  String get noSlotsAvailable => 'No available slots';

  @override
  String get noSlotsAvailableSubtitle =>
      'This doctor has no appointment slots yet.';

  @override
  String get noSlotsThisDay => 'No slots this day';

  @override
  String get noSlotsThisDaySubtitle =>
      'Every slot for this day is booked or has passed. Try another day.';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name shown in the app bar and window title
  ///
  /// In en, this message translates to:
  /// **'Doctor Appointment Booking'**
  String get appTitle;

  /// Label of the retry button shown in error views
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Label of the language toggle button. Deliberately shows the TARGET language's name in its own script, so the value differs per locale (EN shows Arabic, AR shows English)
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get switchLanguage;

  /// Title and submit button of the login page
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Title and submit button of the sign-up page
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// Button that signs the current user out
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Label of the email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label of the password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Label of the display-name input field on sign-up
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// Validation message for an empty or malformed email
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get enterValidEmail;

  /// Validation message for an empty display-name field
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// Validation message for a password below the minimum length
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// Shows which account is authenticated
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// Link on the login page to the sign-up page
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountPrompt;

  /// Link on the sign-up page to the login page
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccountPrompt;

  /// App bar title of the doctors browse list
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctorsTitle;

  /// Hint of the doctors search field
  ///
  /// In en, this message translates to:
  /// **'Search by name or specialty'**
  String get searchDoctors;

  /// Chip that clears the specialty filter
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allSpecialties;

  /// Empty state when the doctors list is empty
  ///
  /// In en, this message translates to:
  /// **'No doctors yet'**
  String get noDoctors;

  /// Empty state body when there are no doctors at all
  ///
  /// In en, this message translates to:
  /// **'Doctors will appear here once they\'re available.'**
  String get noDoctorsSubtitle;

  /// Empty state when search/filter yields no results
  ///
  /// In en, this message translates to:
  /// **'No doctors match'**
  String get noMatches;

  /// Empty state body when search/filter yields no results
  ///
  /// In en, this message translates to:
  /// **'Try a different search or specialty.'**
  String get noMatchesSubtitle;

  /// App bar title of the doctor profile page
  ///
  /// In en, this message translates to:
  /// **'Doctor profile'**
  String get doctorProfile;

  /// Section heading for the doctor's bio
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileBio;

  /// Section heading for the clinic address
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get profileClinic;

  /// Gallery entry button that opens the doctors list
  ///
  /// In en, this message translates to:
  /// **'Browse doctors'**
  String get browseDoctors;

  /// Button on the doctor profile that opens slot selection, and the AppBar title of the slot selection page
  ///
  /// In en, this message translates to:
  /// **'Book appointment'**
  String get bookAppointment;

  /// Empty state when a doctor has no slot documents at all
  ///
  /// In en, this message translates to:
  /// **'No available slots'**
  String get noSlotsAvailable;

  /// Empty state body when a doctor has no slot documents at all
  ///
  /// In en, this message translates to:
  /// **'This doctor has no appointment slots yet.'**
  String get noSlotsAvailableSubtitle;

  /// Empty state when the selected day has no bookable slots left
  ///
  /// In en, this message translates to:
  /// **'No slots this day'**
  String get noSlotsThisDay;

  /// Empty state body when the selected day has no bookable slots left
  ///
  /// In en, this message translates to:
  /// **'Every slot for this day is booked or has passed. Try another day.'**
  String get noSlotsThisDaySubtitle;

  /// Bottom button on the slot selection page that starts the booking transaction
  ///
  /// In en, this message translates to:
  /// **'Confirm booking'**
  String get confirmBooking;

  /// Success heading on the confirmation page after a slot is booked
  ///
  /// In en, this message translates to:
  /// **'Appointment booked!'**
  String get bookingConfirmedTitle;

  /// Button on the confirmation page that returns to the doctors list
  ///
  /// In en, this message translates to:
  /// **'Back to doctors'**
  String get backToDoctors;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'حجز موعد الطبيب';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get switchLanguage => 'English';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get enterValidEmail => 'أدخل عنوان بريد إلكتروني صحيح';

  @override
  String get enterYourName => 'أدخل اسمك';

  @override
  String get passwordTooShort => 'كلمة المرور يجب ألا تقل عن ٨ أحرف';

  @override
  String signedInAs(String email) {
    return 'تم تسجيل الدخول باسم $email';
  }

  @override
  String get noAccountPrompt => 'ليس لديك حساب؟ أنشئ حسابًا';

  @override
  String get haveAccountPrompt => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get doctorsTitle => 'الأطباء';

  @override
  String get searchDoctors => 'ابحث بالاسم أو التخصص';

  @override
  String get allSpecialties => 'الكل';

  @override
  String get noDoctors => 'لا يوجد أطباء بعد';

  @override
  String get noDoctorsSubtitle => 'سيظهر الأطباء هنا عندما يتوفرون.';

  @override
  String get noMatches => 'لا يوجد أطباء مطابقون';

  @override
  String get noMatchesSubtitle => 'جرّب بحثًا أو تخصصًا مختلفًا.';

  @override
  String get doctorProfile => 'ملف الطبيب';

  @override
  String get profileBio => 'نبذة';

  @override
  String get profileClinic => 'العيادة';

  @override
  String get browseDoctors => 'تصفح الأطباء';

  @override
  String get bookAppointment => 'حجز موعد';

  @override
  String get noSlotsAvailable => 'لا توجد مواعيد متاحة';

  @override
  String get noSlotsAvailableSubtitle =>
      'لا توجد مواعيد متاحة لهذا الطبيب بعد.';

  @override
  String get noSlotsThisDay => 'لا توجد مواعيد في هذا اليوم';

  @override
  String get noSlotsThisDaySubtitle =>
      'جميع المواعيد في هذا اليوم محجوزة أو انتهت. جرّب يومًا آخر.';
}

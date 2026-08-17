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

  @override
  String get confirmBooking => 'تأكيد الحجز';

  @override
  String get bookingConfirmedTitle => 'تم حجز الموعد!';

  @override
  String get backToDoctors => 'العودة إلى الأطباء';

  @override
  String get appointmentsTitle => 'مواعيدي';

  @override
  String get upcomingTab => 'القادمة';

  @override
  String get pastTab => 'السابقة';

  @override
  String get cancelAppointment => 'إلغاء';

  @override
  String get cancelAppointmentTitle => 'إلغاء هذا الموعد؟';

  @override
  String get cancelAppointmentBody =>
      'سيؤدي هذا إلى تحرير الموعد ليمكن حجزه من مريض آخر.';

  @override
  String get cancelConfirm => 'نعم، إلغاء';

  @override
  String get cancelDismiss => 'إبقاء الموعد';

  @override
  String get statusScheduled => 'مجدول';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get noUpcomingAppointments => 'لا توجد مواعيد قادمة';

  @override
  String get noUpcomingAppointmentsSubtitle => 'احجز موعدًا مع طبيب ليراه هنا.';

  @override
  String get noPastAppointments => 'لا توجد مواعيد سابقة';

  @override
  String get noPastAppointmentsSubtitle =>
      'ستظهر المواعيد الملغاة والمكتملة هنا.';

  @override
  String get unknownDoctor => 'طبيب غير معروف';

  @override
  String get rescheduleAppointment => 'إعادة الجدولة';

  @override
  String get rescheduleAppointmentTitle => 'إعادة جدولة الموعد';

  @override
  String get rescheduleConfirmedTitle => 'تمت إعادة جدولة الموعد!';

  @override
  String get backToAppointments => 'العودة إلى المواعيد';

  @override
  String get firebaseUnavailableTitle => 'Firebase غير مُهيّأ';

  @override
  String get firebaseUnavailableBody =>
      'لا توجد إعدادات Firebase لهذا الجهاز (google-services.json أو GoogleService-Info.plist)، لذا لا يمكن للتطبيق الوصول إلى بياناته. أضف ملف الإعدادات وأعد التشغيل، أو استخدم نسخة الويب.';
}

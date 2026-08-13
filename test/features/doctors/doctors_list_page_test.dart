import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:doctor_appointment_booking_app/core/entities/doctor.dart';
import 'package:doctor_appointment_booking_app/core/error/app_error.dart' as core;
import 'package:doctor_appointment_booking_app/core/error/result.dart';
import 'package:doctor_appointment_booking_app/di/locator.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/doctors_repository.dart';
import 'package:doctor_appointment_booking_app/features/doctors/domain/use_cases/get_doctors.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/doctors_list_cubit.dart';
import 'package:doctor_appointment_booking_app/features/doctors/presentation/doctors_list_page.dart';
import 'package:doctor_appointment_booking_app/l10n/app_localizations.dart';

class MockDoctorsRepository extends Mock implements DoctorsRepository {}

Doctor doc(String id, String name, String specialty) => Doctor(
      id: id,
      name: name,
      specialty: specialty,
      bio: 'Bio $id',
      rating: 4.5,
      clinicAddress: 'Clinic $id',
      photoUrl: '',
    );

void main() {
  final ana = doc('d1', 'Ana Patel', 'Cardiology');
  final omar = doc('d2', 'Omar Haddad', 'Dermatology');

  late MockDoctorsRepository repository;

  // The page's AppBar hosts LanguageToggleButton, which resolves
  // LocaleService from GetIt — mirror lib/main.dart's setup.
  setUp(() {
    setupLocator();
    repository = MockDoctorsRepository();
  });

  tearDown(resetLocator);

  Widget wrap(DoctorsListCubit cubit) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: const DoctorsListPage(),
        ),
      );

  // Bounded pumps: LoadingView's spinner animates forever, so
  // pumpAndSettle would time out.
  Future<void> pumpLoaded(WidgetTester tester, DoctorsListCubit cubit) async {
    await tester.pumpWidget(wrap(cubit));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders the loaded doctors as cards', (tester) async {
    when(() => repository.getDoctors())
        .thenAnswer((_) async => Success([ana, omar]));
    final cubit = DoctorsListCubit(getDoctors: GetDoctors(repository))..load();

    await pumpLoaded(tester, cubit);

    expect(find.text('Ana Patel'), findsOneWidget);
    expect(find.text('Omar Haddad'), findsOneWidget);
    expect(find.text('4.5'), findsNWidgets(2));
  });

  testWidgets('shows the no-doctors empty state', (tester) async {
    when(() => repository.getDoctors())
        .thenAnswer((_) async => const Success([]));
    final cubit = DoctorsListCubit(getDoctors: GetDoctors(repository))..load();

    await pumpLoaded(tester, cubit);

    expect(find.text('No doctors yet'), findsOneWidget);
  });

  testWidgets('search field filters the list live', (tester) async {
    when(() => repository.getDoctors())
        .thenAnswer((_) async => Success([ana, omar]));
    final cubit = DoctorsListCubit(getDoctors: GetDoctors(repository))..load();

    await pumpLoaded(tester, cubit);
    expect(find.text('Omar Haddad'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pump();

    expect(find.text('Ana Patel'), findsOneWidget);
    expect(find.text('Omar Haddad'), findsNothing);
  });

  testWidgets('a search with no matches shows the no-matches empty state',
      (tester) async {
    when(() => repository.getDoctors())
        .thenAnswer((_) async => Success([ana, omar]));
    final cubit = DoctorsListCubit(getDoctors: GetDoctors(repository))..load();

    await pumpLoaded(tester, cubit);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();

    expect(find.text('No doctors match'), findsOneWidget);
  });

  testWidgets('tapping a specialty chip filters the list', (tester) async {
    when(() => repository.getDoctors())
        .thenAnswer((_) async => Success([ana, omar]));
    final cubit = DoctorsListCubit(getDoctors: GetDoctors(repository))..load();

    await pumpLoaded(tester, cubit);
    expect(find.text('Omar Haddad'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Cardiology'));
    await tester.pump();

    expect(find.text('Ana Patel'), findsOneWidget);
    expect(find.text('Omar Haddad'), findsNothing);
  });

  testWidgets('a failed load shows the error view and retry recovers',
      (tester) async {
    // The repository contract reports failures as Failure, never throws.
    when(() => repository.getDoctors())
        .thenAnswer((_) async => const Failure(core.NetworkError()));
    final cubit = DoctorsListCubit(getDoctors: GetDoctors(repository))..load();

    await pumpLoaded(tester, cubit);
    expect(find.text('Retry'), findsOneWidget);

    when(() => repository.getDoctors())
        .thenAnswer((_) async => Success([ana]));
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Ana Patel'), findsOneWidget);
  });
}

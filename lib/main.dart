import 'package:flutter/material.dart';

import 'di/locator.dart';
import 'shared/theme/app_theme.dart';

void main() {
  // Wire up the service locator before the widget tree is built, so any
  // widget can resolve dependencies via `sl<T>()` during build.
  setupLocator();
  runApp(const DoctorAppointmentApp());
}

/// Temporary root widget for the project scaffold.
///
/// Uses the shared [AppTheme] (Task 5). Replaced in Task 6 (localization)
/// and Task 8 (routing) with the real app shell: MaterialApp.router and
/// locale delegates.
class DoctorAppointmentApp extends StatelessWidget {
  const DoctorAppointmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor Appointment Booking',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const PlaceholderHomePage(),
    );
  }
}

/// Minimal placeholder screen so the app builds and runs.
///
/// Replaced by the real feature pages (doctors list, auth, etc.) in later
/// tasks. Kept stateless and trivial on purpose — no business logic here.
class PlaceholderHomePage extends StatelessWidget {
  const PlaceholderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Appointment Booking')),
      body: const Center(
        child: Text('Project scaffold ready.'),
      ),
    );
  }
}

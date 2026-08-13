import 'package:flutter/material.dart';

import 'app.dart';
import 'data/firebase/firebase_bootstrap.dart';
import 'di/locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Wire up the service locator before the widget tree is built, so any
  // widget can resolve dependencies via `sl<T>()` during build.
  setupLocator();
  // Guarded: succeeds only when Firebase platform config is present
  // (Option A — see FirebaseBootstrap).
  await FirebaseBootstrap.init();
  runApp(const DoctorAppointmentApp());
}

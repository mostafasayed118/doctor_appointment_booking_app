import 'package:flutter/material.dart';

import 'app.dart';
import 'di/locator.dart';

void main() {
  // Wire up the service locator before the widget tree is built, so any
  // widget can resolve dependencies via `sl<T>()` during build.
  setupLocator();
  runApp(const DoctorAppointmentApp());
}

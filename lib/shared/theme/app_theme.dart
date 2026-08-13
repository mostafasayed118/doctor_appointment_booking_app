import 'package:flutter/material.dart';

/// Central place for the app's visual identity.
///
/// A single [ThemeData] source keeps colors and text styles consistent
/// across every screen. The seed color drives the Material 3 color scheme,
/// so light/dark variants are derived automatically rather than hand-picked.
abstract final class AppTheme {
  /// Medical-teal seed — calm, clinical, and distinct from the default
  /// Material purple.
  static const Color _seed = Color(0xFF00897B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
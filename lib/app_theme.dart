import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF005EB8);
  static const accentColor = Color(0xFFF2B632);
  static const backgroundColor = Color(0xFFF9FAFB);

  static ThemeData build({bool highContrast = false}) {
    final base = highContrast ? ThemeData.highContrastLight() : ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.openSans(
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.openSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: GoogleFonts.openSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.openSans(fontSize: 16),
        bodyMedium: GoogleFonts.openSans(fontSize: 14),
        bodySmall: GoogleFonts.openSans(fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(16),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minLeadingWidth: 24,
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

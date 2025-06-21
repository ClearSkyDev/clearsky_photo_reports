import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    textTheme: GoogleFonts.robotoTextTheme(),
    scaffoldBackgroundColor: Colors.grey[50],
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: Colors.grey[900],
  );

  static ThemeData clearSkyTheme = ThemeData(
    primaryColor: const Color(0xFF4DB8FF),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: const Color(0xFFFFD54F),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF8A65),
        foregroundColor: Colors.white,
      ),
    ),
  );

  // Build a high-contrast theme starting from a high-contrast color scheme
  // and customizing common properties.
  static ThemeData highContrastTheme = ThemeData.from(
    colorScheme: const ColorScheme.highContrastLight(),
  ).copyWith(
    textTheme: GoogleFonts.robotoMonoTextTheme(),
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.highContrastLight().copyWith(
      secondary: Colors.orange,
    ),
  );
}

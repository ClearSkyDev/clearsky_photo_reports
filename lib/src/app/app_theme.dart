import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Common color constants used by the Clear Sky theme.
  static const Color clearSkyBlue = Color(0xFF005DAA);
  static const Color sunYellow = Color(0xFFF6BE00);
  static const Color matteBlack = Color(0xFF202020);
  static const Color lightBackground = Color(0xFFF2F2F2);

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
    colorScheme: ColorScheme.light(
      primary: clearSkyBlue,
      secondary: sunYellow,
      background: lightBackground,
      onPrimary: Colors.white,
      onSecondary: matteBlack,
    ),
    scaffoldBackgroundColor: lightBackground,
    textTheme: GoogleFonts.robotoTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: clearSkyBlue,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: sunYellow,
        foregroundColor: matteBlack,
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

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

  // Build a high-contrast theme using the named constructor.
  static ThemeData highContrastTheme = ThemeData.highContrastLight().copyWith(
    textTheme: GoogleFonts.robotoMonoTextTheme(),
  );
}

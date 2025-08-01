import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Common color constants used by the Clear Sky theme.
  static const Color clearSkyBlue = Color(0xFF007BFF);
  static const Color sunYellow = Color(0xFFF6BE00);
  static const Color matteBlack = Color(0xFF202020);
  static const Color lightBackground = Colors.white;

  /// Shadow used to outline all text.
  static const List<Shadow> _textOutline = [
    Shadow(
      offset: Offset(0.5, 0.5),
      blurRadius: 1.5,
      color: Colors.black,
    ),
  ];

  /// Adds a subtle black outline to every style in a [TextTheme].
  static TextTheme _outlinedTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(shadows: _textOutline),
      displayMedium: base.displayMedium?.copyWith(shadows: _textOutline),
      displaySmall: base.displaySmall?.copyWith(shadows: _textOutline),
      headlineLarge: base.headlineLarge?.copyWith(shadows: _textOutline),
      headlineMedium: base.headlineMedium?.copyWith(shadows: _textOutline),
      headlineSmall: base.headlineSmall?.copyWith(shadows: _textOutline),
      titleLarge: base.titleLarge?.copyWith(shadows: _textOutline),
      titleMedium: base.titleMedium?.copyWith(shadows: _textOutline),
      titleSmall: base.titleSmall?.copyWith(shadows: _textOutline),
      bodyLarge: base.bodyLarge?.copyWith(shadows: _textOutline),
      bodyMedium: base.bodyMedium?.copyWith(shadows: _textOutline),
      bodySmall: base.bodySmall?.copyWith(shadows: _textOutline),
      labelLarge: base.labelLarge?.copyWith(shadows: _textOutline),
      labelMedium: base.labelMedium?.copyWith(shadows: _textOutline),
      labelSmall: base.labelSmall?.copyWith(shadows: _textOutline),
    );
  }

  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Quicksand',
    primaryColor: clearSkyBlue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      color: clearSkyBlue,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(color: Colors.black, fontWeight: FontWeight.w400),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: clearSkyBlue),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: clearSkyBlue,
        foregroundColor: Colors.white,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: clearSkyBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    iconTheme: const IconThemeData(color: clearSkyBlue),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    colorScheme: ThemeData.dark().colorScheme.copyWith(
      primary: clearSkyBlue,
      secondary: sunYellow,
    ),
    textTheme:
        _outlinedTextTheme(GoogleFonts.quicksandTextTheme(ThemeData.dark().textTheme)),
    scaffoldBackgroundColor: Colors.grey[900],
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

  static ThemeData clearSkyTheme = ThemeData(
    colorScheme: ColorScheme.light(
      primary: clearSkyBlue,
      secondary: sunYellow,
      surface: lightBackground,
      onPrimary: Colors.white,
      onSecondary: matteBlack,
    ),
    scaffoldBackgroundColor: lightBackground,
    textTheme: _outlinedTextTheme(GoogleFonts.quicksandTextTheme()),
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
    textTheme: _outlinedTextTheme(GoogleFonts.quicksandTextTheme()),
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

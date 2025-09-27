import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: const Color(0xFF04192a),
      primaryColor: const Color(0xFF17efdf),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF17efdf),
        secondary: Color(0xFF17efdf),
        background: Color(0xFF04192a),
        surface: Color(0xFF0d263a),
        onPrimary: Color(0xFF04192a),
        onSecondary: Color(0xFF04192a),
        onBackground: Color(0xFFe9ecef),
        onSurface: Color(0xFFe9ecef),
        error: Color(
          0xFFcf6679,
        ), // Material Design standard dark theme error color
        onError: Color(0xFF000000),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0d263a),
        foregroundColor: Color(0xFFe9ecef),
      ),
      cardTheme: const CardThemeData(color: Color(0xFF0d263a), elevation: 4),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFe9ecef)),
        bodyMedium: TextStyle(color: Color(0xFFa0b3c4)),
        headlineMedium: TextStyle(color: Color(0xFFe9ecef)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF17efdf),
          foregroundColor: const Color(0xFF04192a),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF17efdf)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Color(0xFFa0b3c4)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFa0b3c4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF17efdf)),
        ),
      ),
    );
  }
}

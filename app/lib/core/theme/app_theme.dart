import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _black = Color(0xFF0A0A0A);
  static const Color _darkGray = Color(0xFF1A1A1A);
  static const Color _surface = Color(0xFF222222);
  static const Color _accent = Color(0xFFCC0000);
  static const Color _textPrimary = Color(0xFFEEEEEE);
  static const Color _textSecondary = Color(0xFF888888);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _black,
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          surface: _surface,
          onSurface: _textPrimary,
          secondary: _textSecondary,
        ),
        textTheme: GoogleFonts.notoSerifJpTextTheme(
          ThemeData.dark().textTheme.copyWith(
                bodyLarge: const TextStyle(color: _textPrimary, height: 1.8),
                bodyMedium: const TextStyle(color: _textPrimary, height: 1.8),
                titleLarge: const TextStyle(
                    color: _textPrimary, fontWeight: FontWeight.bold),
              ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _black,
          elevation: 0,
          titleTextStyle: TextStyle(
              color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: _textPrimary),
        ),
        cardTheme: CardThemeData(
          color: _darkGray,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dividerColor: _surface,
        iconTheme: const IconThemeData(color: _textSecondary),
      );
}

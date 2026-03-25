import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _lightBackground = Color(0xFFFAFAF8);
  static const _darkBackground = Color(0xFF1A1A2E);
  static const _accent = Color(0xFFB8860B);
  static const _accentLight = Color(0xFFDAA520);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        surface: _lightBackground,
        primary: _accent,
        secondary: _accentLight,
        onSurface: const Color(0xFF2D2D2D),
      ),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: GoogleFonts.notoSansTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2D2D2D),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: _accent.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.notoSans(fontSize: 13),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        surface: _darkBackground,
        primary: _accentLight,
        secondary: _accent,
        onSurface: const Color(0xFFE8E8E8),
      ),
      scaffoldBackgroundColor: _darkBackground,
      textTheme: GoogleFonts.notoSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.notoSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE8E8E8),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: _accentLight.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.notoSans(fontSize: 13),
      ),
    );
  }
}

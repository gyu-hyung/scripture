import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

class WidgetTheme {
  final String id;
  final Color background;
  final Color textColor;
  final Color accentColor;

  const WidgetTheme({
    required this.id,
    required this.background,
    required this.textColor,
    required this.accentColor,
  });

  String localizedName(AppLocalizations l10n) => switch (id) {
    AppConstants.themeModernDark => l10n.themeModernDark,
    _ => id,
  };

  static const modernDark = WidgetTheme(
    id: AppConstants.themeModernDark,
    background: Color(0xFF15151C),
    textColor: Colors.white,
    accentColor: Color(0xFFB8860B),
  );

  static const pureWhite = WidgetTheme(
    id: AppConstants.themePureWhite,
    background: Colors.white,
    textColor: Color(0xFF2D2D2D),
    accentColor: Color(0xFF0D47A1),
  );

  static const pastelRed = WidgetTheme(
    id: AppConstants.themePastelRed,
    background: Color(0xFFFCE4EC),
    textColor: Color(0xFF880E4F),
    accentColor: Color(0xFFF06292),
  );

  static const pastelOrange = WidgetTheme(
    id: AppConstants.themePastelOrange,
    background: Color(0xFFFFF3E0),
    textColor: Color(0xFFE65100),
    accentColor: Color(0xFFFFB74D),
  );

  static const pastelYellow = WidgetTheme(
    id: AppConstants.themePastelYellow,
    background: Color(0xFFFFFDE7),
    textColor: Color(0xFFF57F17),
    accentColor: Color(0xFFFFF176),
  );

  static const pastelGreen = WidgetTheme(
    id: AppConstants.themePastelGreen,
    background: Color(0xFFE8F5E9),
    textColor: Color(0xFF1B5E20),
    accentColor: Color(0xFF81C784),
  );

  static const pastelTeal = WidgetTheme(
    id: AppConstants.themePastelTeal,
    background: Color(0xFFE0F2F1),
    textColor: Color(0xFF004D40),
    accentColor: Color(0xFF4DB6AC),
  );

  static const pastelBlue = WidgetTheme(
    id: AppConstants.themePastelBlue,
    background: Color(0xFFE3F2FD),
    textColor: Color(0xFF0D47A1),
    accentColor: Color(0xFF64B5F6),
  );

  static const pastelIndigo = WidgetTheme(
    id: AppConstants.themePastelIndigo,
    background: Color(0xFFE8EAF6),
    textColor: Color(0xFF1A237E),
    accentColor: Color(0xFF7986CB),
  );

  static const pastelPurple = WidgetTheme(
    id: AppConstants.themePastelPurple,
    background: Color(0xFFF3E5F5),
    textColor: Color(0xFF4A148C),
    accentColor: Color(0xFFBA68C8),
  );

  static const List<WidgetTheme> all = [
    modernDark,
    pureWhite,
    pastelRed,
    pastelOrange,
    pastelYellow,
    pastelGreen,
    pastelTeal,
    pastelBlue,
    pastelIndigo,
    pastelPurple,
  ];
}

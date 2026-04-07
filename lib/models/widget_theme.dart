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
    AppConstants.themeMinimalistLight => l10n.themeMinimalistLight,
    AppConstants.themeSereneBlue => l10n.themeSereneBlue,
    AppConstants.themeNatureGreen => l10n.themeNatureGreen,
    AppConstants.themeCustomPhoto => l10n.themeCustomPhoto,
    _ => id,
  };

  static const modernDark = WidgetTheme(
    id: AppConstants.themeModernDark,
    background: Color(0xFF15151C),
    textColor: Colors.white,
    accentColor: Color(0xFFB8860B),
  );

  static const minimalistLight = WidgetTheme(
    id: AppConstants.themeMinimalistLight,
    background: Color(0xFFF8F9FA),
    textColor: Color(0xFF2D2D2D),
    accentColor: Color(0xFF0D47A1),
  );

  static const sereneBlue = WidgetTheme(
    id: AppConstants.themeSereneBlue,
    background: Color(0xFF0D47A1),
    textColor: Colors.white,
    accentColor: Color(0xFFBBDEFB),
  );

  static const natureGreen = WidgetTheme(
    id: AppConstants.themeNatureGreen,
    background: Color(0xFF2E7D32),
    textColor: Colors.white,
    accentColor: Color(0xFFC8E6C9),
  );

  // 사진 테마: 실제 배경은 선택한 사진, 텍스트 색상은 흰색 사용
  static const customPhoto = WidgetTheme(
    id: AppConstants.themeCustomPhoto,
    background: Color(0xFF1A1A1A), // 사진 없을 때 폴백
    textColor: Colors.white,
    accentColor: Color(0xFFFFFFFF),
  );

  static const List<WidgetTheme> all = [
    modernDark,
    minimalistLight,
    sereneBlue,
    natureGreen,
    customPhoto,
  ];
}

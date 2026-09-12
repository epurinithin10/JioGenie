import 'package:flutter/material.dart';

class JioColors {
  // Brand Colors
  static const Color jioBlue = Color(0xFF0057FF);
  static const Color jioNavy = Color(0xFF0A2885);
  static const Color jioDeepNavy = Color(0xFF00175A);
  static const Color jioBlueLight = Color(0xFFEBF2FF);
  static const Color jioRed = Color(0xFFE50027);
  static const Color jioRedHover = Color(0xFFC70022);
  static const Color jioCyan = Color(0xFF00C2FF);
  static const Color jioGreen = Color(0xFF00D284);
  static const Color jioYellow = Color(0xFFF59E0B);

  // Backgrounds
  static const Color bgPrimary = Color(0xFFF5F7FB);
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgTertiary = Color(0xFFEEF2F8);
  static const Color bgHover = Color(0xFFE4EAF4);

  // Borders
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderDefault = Color(0xFFD2DCE8);
  static const Color borderFocus = Color(0xFF0057FF);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF8492A6);
  static const Color textInverted = Color(0xFFFFFFFF);

  // Shadows
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: const Color(0xFF00175A).withValues(alpha: 0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: const Color(0xFF00175A).withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: const Color(0xFF00175A).withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/jio_colors.dart';

class JioTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: JioColors.jioBlue,
      scaffoldBackgroundColor: JioColors.bgPrimary,
      colorScheme: const ColorScheme.light(
        primary: JioColors.jioBlue,
        secondary: JioColors.jioNavy,
        surface: JioColors.bgSecondary,
        error: JioColors.jioRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: JioColors.textPrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: JioColors.jioNavy,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: JioColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: JioColors.textPrimary,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: JioColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: JioColors.bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: JioColors.borderSubtle, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: JioColors.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: JioColors.borderSubtle, width: 1),
        ),
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: JioColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

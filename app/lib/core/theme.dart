import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF4F3EF);
  static const Color ink = Color(0xFF0A0A0A);
  static const Color accent = Color(0xFFE23A1E);
  static const Color muted = Color(0xFF888888);
  static const Color hairlineStrong = Color(0xFFD4D3CD);
  static const Color hairlineLight = Color(0xFFE3E2DC);
  static const Color barTrack = Color(0xFFDEDED7);
}

class AppTextStyles {
  AppTextStyles._();

  static final TextStyle hero = GoogleFonts.archivo(
    fontWeight: FontWeight.w800,
    fontSize: 48,
    letterSpacing: -0.96, // -0.02em × 48px
    color: AppColors.ink,
    height: 1.1,
  );

  static final TextStyle sectionTitle = GoogleFonts.archivo(
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 1.32, // 0.12em × 11px
    color: AppColors.muted,
    height: 1.4,
  );

  static final TextStyle body = GoogleFonts.archivo(
    fontWeight: FontWeight.w500,
    fontSize: 15,
    color: AppColors.ink,
    height: 1.5,
  );

  static final TextStyle bodyStrong = GoogleFonts.archivo(
    fontWeight: FontWeight.w600,
    fontSize: 15,
    color: AppColors.ink,
    height: 1.5,
  );

  static final TextStyle amount = GoogleFonts.archivo(
    fontWeight: FontWeight.w700,
    fontSize: 20,
    color: AppColors.ink,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      surface: AppColors.background,
      primary: AppColors.ink,
      onPrimary: AppColors.background,
      secondary: AppColors.accent,
      onSecondary: AppColors.background,
    ),
    textTheme: GoogleFonts.archivoTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    cardTheme: const CardThemeData(elevation: 0, color: AppColors.background),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairlineLight,
      thickness: 1,
      space: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.background,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
    ),
  );
}

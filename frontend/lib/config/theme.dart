import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF3B5BDB);
  static const primaryLight = Color(0xFF748FFC);
  static const primaryDark = Color(0xFF2F4AC0);
  static const secondary = Color(0xFF4DABF7);
  static const accent = Color(0xFFFF6B35);

  static const success = Color(0xFF40C057);
  static const warning = Color(0xFFFFD43B);
  static const error = Color(0xFFFA5252);
  static const info = Color(0xFF4DABF7);

  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F5);

  static const textPrimary = Color(0xFF1A1D23);
  static const textSecondary = Color(0xFF6C757D);
  static const textHint = Color(0xFFADB5BD);

  static const divider = Color(0xFFE9ECEF);
  static const border = Color(0xFFDEE2E6);

  // Couleurs niveaux scolaires (Burkina Faso)
  static const primaire = Color(0xFF40C057);
  static const college = Color(0xFF339AF0);
  static const lycee = Color(0xFFFF922B);
  static const universite = Color(0xFFAE3EC9);
  static const concours = Color(0xFFFA5252);

  // Gradient principal
  static const gradientStart = Color(0xFF3B5BDB);
  static const gradientEnd = Color(0xFF4DABF7);
}

// Shorthand to avoid repeating fontFamily on every TextStyle
TextStyle _p(double size, FontWeight weight, [Color? color]) => TextStyle(
      fontFamily: 'Poppins',
      fontSize: size,
      fontWeight: weight,
      color: color,
    );

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      textTheme: TextTheme(
        displayLarge:  _p(32, FontWeight.w700, AppColors.textPrimary),
        displayMedium: _p(24, FontWeight.w700, AppColors.textPrimary),
        displaySmall:  _p(20, FontWeight.w600, AppColors.textPrimary),
        headlineLarge:  _p(18, FontWeight.w600, AppColors.textPrimary),
        headlineMedium: _p(16, FontWeight.w600, AppColors.textPrimary),
        headlineSmall:  _p(14, FontWeight.w600, AppColors.textPrimary),
        bodyLarge:  _p(16, FontWeight.w400, AppColors.textPrimary),
        bodyMedium: _p(14, FontWeight.w400, AppColors.textPrimary),
        bodySmall:  _p(12, FontWeight.w400, AppColors.textSecondary),
        labelLarge:  _p(14, FontWeight.w600),
        labelMedium: _p(12, FontWeight.w500),
        labelSmall:  _p(10, FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _p(18, FontWeight.w700, AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _p(14, FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _p(14, FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: _p(14, FontWeight.w400, AppColors.textHint),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: _p(13, FontWeight.w500),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
    );
  }
}

// Extension utilitaire
extension ColorX on Color {
  Color withOpacityX(double opacity) => withValues(alpha: opacity);
}

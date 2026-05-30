import 'package:flutter/material.dart';

/// Palette de couleurs cohérente basée sur #5863F8
class AppColors {
  AppColors._();

  // ── Échelle primaire #5863F8 (50 à 900) ──────────────────────────────────
  static const Color primary50 = Color(0xFFF0F3FF);
  static const Color primary100 = Color(0xFFE0E6FF);
  static const Color primary200 = Color(0xFFC0CCFF);
  static const Color primary300 = Color(0xFFA0B3FF);
  static const Color primary400 = Color(0xFF8099FF);
  static const Color primary = Color(0xFF5863F8);      // 500 - base primaire
  static const Color primary600 = Color(0xFF4752E8);   // hover
  static const Color primary700 = Color(0xFF3641D8);   // active
  static const Color primary800 = Color(0xFF2530C8);   // pressed
  static const Color primary900 = Color(0xFF141FB8);   // dark

  // ── Variantes d'état pour la couleur primaire ─────────────────────────────
  static const Color primaryHover = Color(0xFF4752E8);
  static const Color primaryActive = Color(0xFF3641D8);
  static const Color primaryPressed = Color(0xFF2530C8);
  static const Color primaryDisabled = Color(0xFFE0E6FF);

  // ── Palette neutre (Backgrounds, Borders, Textes) ─────────────────────────
  static const Color background = Color(0xFFF8FAFC);   // Page bg
  static const Color surface = Color(0xFFFFFFFF);      // Cards, panels
  static const Color surfaceHover = Color(0xFFF1F5F9);
  static const Color surfaceActive = Color(0xFFE2E8F0);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  static const Color border = Color(0xFFE2E8F0);       // Borders
  static const Color borderLight = Color(0xFFF1F5F9);  // Light borders
  static const Color borderDark = Color(0xFFCBD5E1);   // Dark borders

  static const Color textPrimary = Color(0xFF0F172A);    // Texte principal
  static const Color textSecondary = Color(0xFF64748B);  // Texte secondaire
  static const Color textTertiary = Color(0xFF94A3B8);   // Texte tertiaire
  static const Color textHint = Color(0xFFC0CCFF);       // Texte désactivé/hint
  static const Color textDisabled = Color(0xFFC0CCFF);   // Texte désactivé
  static const Color textInverse = Color(0xFFFFFFFF);    // Texte sur fond sombre

  // ── Couleurs sémantiques ──────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF15803D);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFECACA);
  static const Color errorDark = Color(0xFFB91C1C);

  static const Color info = Color(0xFF5863F8);
  static const Color infoLight = Color(0xFFE0E6FF);

  // ── Niveaux scolaires (Burkina Faso) ──────────────────────────────────────
  // Utiliser les nuances de la palette primaire et les couleurs sémantiques
  static const Color primaire = Color(0xFF22C55E);        // Vert (succès)
  static const Color college = Color(0xFF5863F8);         // Bleu primaire
  static const Color lycee = Color(0xFF22C55E);           // Vert
  static const Color universite = Color(0xFFF59E0B);      // Orange (warning)
  static const Color concours = Color(0xFFEF4444);        // Rouge (error)

  // ── Dégradés ──────────────────────────────────────────────────────────────
  // Dégradé primaire
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF4752E8), Color(0xFF5863F8), Color(0xFF7485FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dégradé success
  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dégradé warning
  static const LinearGradient gradientWarning = LinearGradient(
    colors: [Color(0xFFC2410C), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── Helpers pour les TextStyles ───────────────────────────────────────────────
TextStyle _inter(double size, FontWeight weight, [Color? color]) => TextStyle(
  fontFamily: 'Inter',
  fontSize: size,
  fontWeight: weight,
  color: color ?? AppColors.textPrimary,
);

TextStyle _p(double size, FontWeight weight, [Color? color]) => TextStyle(
  fontFamily: 'Poppins',
  fontSize: size,
  fontWeight: weight,
  color: color ?? AppColors.textPrimary,
);

/// Thème Light cohérent avec la palette #5863F8
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.primary600,
        tertiary: AppColors.success,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textInverse,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',

      // ── TextTheme ─────────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: _inter(32, FontWeight.w800, AppColors.textPrimary),
        displayMedium: _inter(24, FontWeight.w800, AppColors.textPrimary),
        displaySmall: _inter(20, FontWeight.w700, AppColors.textPrimary),
        headlineLarge: _inter(18, FontWeight.w700, AppColors.textPrimary),
        headlineMedium: _inter(16, FontWeight.w700, AppColors.textPrimary),
        headlineSmall: _inter(14, FontWeight.w700, AppColors.textPrimary),
        bodyLarge: _inter(16, FontWeight.w500, AppColors.textPrimary),
        bodyMedium: _inter(14, FontWeight.w500, AppColors.textPrimary),
        bodySmall: _inter(12, FontWeight.w400, AppColors.textSecondary),
        labelLarge: _inter(14, FontWeight.w700, AppColors.primary),
        labelMedium: _inter(12, FontWeight.w600, AppColors.primary),
        labelSmall: _inter(10, FontWeight.w600, AppColors.textSecondary),
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _inter(18, FontWeight.w700, AppColors.textPrimary),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: AppColors.textTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _inter(14, FontWeight.w700),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          disabledForegroundColor: AppColors.textTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _inter(14, FontWeight.w700),
        ),
      ),

      // ── TextButton ────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: _inter(14, FontWeight.w700),
        ),
      ),

      // ── InputDecoration ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
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
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        hintStyle: _inter(14, FontWeight.w400, AppColors.textTertiary),
        labelStyle: _inter(14, FontWeight.w500, AppColors.textSecondary),
        errorStyle: _inter(12, FontWeight.w400, AppColors.error),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 16,
      ),

      // ── CheckBox ──────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          if (states.contains(MaterialState.disabled)) return AppColors.primaryDisabled;
          return AppColors.surface;
        }),
        side: const BorderSide(
  color: AppColors.border,
),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      // ── RadioButton ───────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          if (states.contains(MaterialState.disabled)) return AppColors.primaryDisabled;
          return Colors.transparent;
        }),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return AppColors.textTertiary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          return AppColors.border;
        }),
      ),

      // ── Slider ────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.primary,
        disabledActiveTrackColor: AppColors.primaryDisabled,
        disabledInactiveTrackColor: AppColors.border,
        disabledThumbColor: AppColors.textTertiary,
        overlayColor: AppColors.primary.withOpacity(0.12),
      ),

      // ── Snackbar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: _inter(14, FontWeight.w500, Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: _inter(18, FontWeight.w700, AppColors.textPrimary),
        contentTextStyle: _inter(14, FontWeight.w400, AppColors.textSecondary),
      ),

      // ── BottomSheet ───────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // ── ProgressIndicator ─────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        circularTrackColor: AppColors.border,
        color: AppColors.primary,
        linearTrackColor: AppColors.border,
        linearMinHeight: 4,
      ),

      // ── List Tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedColor: AppColors.primary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: _inter(12, FontWeight.w400, AppColors.textSecondary),
      ),
    );
  }
}

// Extension utilitaire
extension ColorX on Color {
  Color withOpacityX(double opacity) => withValues(alpha: opacity);
}

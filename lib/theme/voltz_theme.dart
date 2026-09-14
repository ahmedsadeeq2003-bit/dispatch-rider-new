import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// Voltz design system
/// ============================================================================
/// A dark, high-contrast identity for the eco-delivery surface of the app:
/// near-black surfaces, a single neon-green accent reserved for progress and
/// confirmation, and bordered (not shadowed) cards — shadows don't read on a
/// dark background, borders do. Lives alongside the NovaScale system
/// (theme/app_theme.dart) rather than replacing it; screens under
/// screens/voltz/ opt into this theme explicitly instead of inheriting
/// MaterialApp's light theme.
/// ============================================================================

class VoltzColors {
  VoltzColors._();

  // Accent — the one neon signal, reserved for progress/selection/success.
  static const Color neon = Color(0xFF39FF8A);
  static const Color neonDim = Color(0xFF2ED474);
  static const Color neonMuted = Color(0xFF1F6E45);

  // Surfaces
  static const Color background = Color(0xFF0A0D0C);
  static const Color surface = Color(0xFF121613);
  static const Color surfaceRaised = Color(0xFF181F1B);
  static const Color surfaceSunken = Color(0xFF070908);
  static const Color border = Color(0xFF232B26);
  static const Color borderStrong = Color(0xFF34403A);

  // Text
  static const Color textPrimary = Color(0xFFF3FAF5);
  static const Color textSecondary = Color(0xFFA3B3AA);
  static const Color textMuted = Color(0xFF6C7A72);

  // Status — never color alone, always paired with an icon/label.
  static const Color success = neon;
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5C5C);
  static const Color info = Color(0xFF4FA8FF);

  static const Color scrim = Color(0x99000000);
}

class VoltzSpacing {
  VoltzSpacing._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;
  static const double radiusPill = 999;
}

class VoltzText {
  VoltzText._();

  static final TextStyle _grotesk = GoogleFonts.spaceGrotesk();
  static final TextStyle _inter = GoogleFonts.inter();

  static final TextStyle display = _grotesk.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: VoltzColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.6,
  );

  static final TextStyle h1 = _grotesk.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: VoltzColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static final TextStyle h2 = _grotesk.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: VoltzColors.textPrimary,
    letterSpacing: -0.2,
  );

  static final TextStyle h3 = _grotesk.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: VoltzColors.textPrimary,
  );

  static final TextStyle body = _inter.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: VoltzColors.textPrimary,
    height: 1.45,
  );

  static final TextStyle bodyMuted = _inter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: VoltzColors.textSecondary,
    height: 1.4,
  );

  static final TextStyle caption = _inter.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: VoltzColors.textSecondary,
  );

  static final TextStyle label = _inter.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: VoltzColors.textMuted,
    letterSpacing: 0.8,
  );

  static final TextStyle button = _inter.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  static final TextStyle numericLg = _grotesk.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: VoltzColors.textPrimary,
    letterSpacing: -0.4,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final TextStyle numericMd = _grotesk.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: VoltzColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class VoltzTheme {
  VoltzTheme._();

  static ThemeData get dark {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.dark);

    return base.copyWith(
      scaffoldBackgroundColor: VoltzColors.background,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: VoltzColors.neon,
        onPrimary: VoltzColors.surfaceSunken,
        secondary: VoltzColors.neon,
        surface: VoltzColors.surface,
        onSurface: VoltzColors.textPrimary,
        error: VoltzColors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: VoltzColors.background,
        foregroundColor: VoltzColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: VoltzText.h2,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: VoltzColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VoltzColors.neon,
          foregroundColor: VoltzColors.surfaceSunken,
          disabledBackgroundColor: VoltzColors.neonMuted,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: VoltzText.button,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VoltzColors.textPrimary,
          side: const BorderSide(color: VoltzColors.border, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: VoltzText.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VoltzColors.neon,
          textStyle: VoltzText.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VoltzColors.surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
          borderSide: const BorderSide(color: VoltzColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
          borderSide: const BorderSide(color: VoltzColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
          borderSide: const BorderSide(color: VoltzColors.neon, width: 1.6),
        ),
        labelStyle: VoltzText.bodyMuted,
        hintStyle: VoltzText.bodyMuted,
      ),
      cardTheme: CardThemeData(
        color: VoltzColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VoltzSpacing.radiusMd),
          side: const BorderSide(color: VoltzColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: VoltzColors.border,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? VoltzColors.neon : VoltzColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected)
            ? VoltzColors.neonMuted
            : VoltzColors.surfaceRaised),
        trackOutlineColor: WidgetStateProperty.all(VoltzColors.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? VoltzColors.neon : Colors.transparent),
        checkColor: WidgetStateProperty.all(VoltzColors.surfaceSunken),
        side: const BorderSide(color: VoltzColors.borderStrong, width: 1.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VoltzColors.surfaceRaised,
        contentTextStyle: VoltzText.body,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VoltzSpacing.radiusSm),
          side: const BorderSide(color: VoltzColors.border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: VoltzColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(VoltzSpacing.radiusXl)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================================
/// NovaScale design system
/// ============================================================================
/// A rider-first logistics product identity: confident indigo brand, a single
/// high-energy signal color reserved for the ONE thing that matters most on
/// screen (go online, accept a job, confirm), and calm status colors that
/// never rely on hue alone. Built for a rider glancing at a phone mid-ride —
/// bigger touch targets, higher contrast, fewer simultaneous focal points.
///
/// Class names (AppColors/AppText/AppSpacing) are kept stable across the
/// redesign so every existing screen's `AppColors.xxx` reference keeps
/// working — only the values and the available token set changed.
/// ============================================================================

class AppColors {
  AppColors._();

  // Brand — an electric indigo, distinct from the red/orange/teal every
  // other delivery app already owns.
  static const Color primary = Color(0xFF5B4FE9);
  static const Color primaryDark = Color(0xFF4038C4);
  static const Color primaryLight = Color(0xFF8B7FFF);

  // Signal — reserved for the single most important action on a screen
  // (Go Online, Accept, Confirm & Pay). Never used decoratively.
  static const Color signal = Color(0xFFFF6B35);
  static const Color signalDark = Color(0xFFE34F1B);

  // Card accent palette — rotate across dashboard tiles / category chips.
  static const Color accentPink = Color(0xFFFF4D8D);
  static const Color accentAmber = Color(0xFFFFB020);
  static const Color accentGreen = Color(0xFF17C666);
  static const Color accentBlue = Color(0xFF2D9CFF);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentTeal = Color(0xFF14B8A6);

  // Back-compat aliases (pre-redesign token names still referenced by a few
  // screens) — kept so this isn't a mass find-replace across the codebase.
  static const Color secondary = accentPurple;
  static const Color tertiary = accentTeal;
  static const Color accentYellow = accentAmber;

  // Status — communicated with icon/shape too, never color alone.
  static const Color online = Color(0xFF16C784); // rider available
  static const Color offline = Color(0xFF9AA0AE); // rider unavailable
  static const Color success = Color(0xFF16C784);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF4757);
  static const Color info = Color(0xFF2E9CFF);
  static const Color money = Color(0xFF0E9F6E); // earnings figures

  // Neutrals
  static const Color background = Color(0xFFF6F6FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFEFEFF8);
  static const Color textPrimary = Color(0xFF14141F);
  static const Color textSecondary = Color(0xFF666B80);
  static const Color textMuted = Color(0xFF9497A8);
  static const Color border = Color(0xFFE7E7F2);
  static const Color scrim = Color(0x66101018);

  // Map / dark surfaces (bottom sheets over a map, floating controls)
  static const Color mapControlSurface = Color(0xFFFFFFFF);
  static const Color inkSurface = Color(0xFF14141F);
}

class AppGradients {
  AppGradients._();

  /// The ONE signature gradient in the app — reserved for the online/earnings
  /// hero surface on the rider home screen. Not reused elsewhere.
  static const LinearGradient heroBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5B4FE9), Color(0xFF8B5CF6)],
  );

  static const LinearGradient heroOnline = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16C784), Color(0xFF0E9F6E)],
  );

  static const LinearGradient heroOffline = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B7080), Color(0xFF4A4E5C)],
  );
}

class AppSpacing {
  AppSpacing._();
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusPill = 999;
}

/// Motion tokens — fast, purposeful, consistent. See widgets/motion.dart for
/// the reusable transition/animation helpers built on top of these.
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 380);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve pop = Curves.easeOutBack;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF14141F).withAlpha(10),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> floating = [
    BoxShadow(
      color: const Color(0xFF14141F).withAlpha(20),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> sheet = [
    BoxShadow(
      color: const Color(0xFF14141F).withAlpha(30),
      blurRadius: 32,
      offset: const Offset(0, -8),
    ),
  ];
}

class AppText {
  AppText._();

  static final TextStyle _sora = GoogleFonts.sora();
  static final TextStyle _inter = GoogleFonts.inter();

  // Hero numeral — the single biggest thing on a screen (earnings figure).
  static final TextStyle display = _sora.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.8,
  );

  static final TextStyle h1 = _sora.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static final TextStyle h2 = _sora.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static final TextStyle h3 = _sora.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static final TextStyle body = _inter.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static final TextStyle bodyMuted = _inter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static final TextStyle caption = _inter.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // Small uppercase eyebrow/section label, e.g. "TODAY", "PICKUP".
  static final TextStyle label = _inter.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 0.8,
  );

  static final TextStyle button = _inter.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  // Tabular numerals for money/stat figures so digits don't jitter widths.
  static final TextStyle numericLg = _sora.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final TextStyle numericMd = _sora.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.signal,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.h2,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withAlpha(90),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: AppText.button,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          textStyle: AppText.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppText.button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        labelStyle: AppText.bodyMuted,
        hintStyle: AppText.bodyMuted,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppText.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withAlpha(24),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppText.caption.copyWith(
            color: selected ? AppColors.primary : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textMuted,
          );
        }),
      ),
    );
  }
}

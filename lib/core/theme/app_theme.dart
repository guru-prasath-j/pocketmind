import 'package:flutter/material.dart';

/// Brand colours that are the same in light and dark mode.
///
/// Anything that changes with the theme (backgrounds, surfaces, borders,
/// text, accent) lives in [AppPalette] — read it with `context.colors`.
abstract final class AppColors {
  // Brand violet.
  static const primary = Color(0xFF8B5CF6);
  static const primaryDeep = Color(0xFF6D28D9);
  static const lavender = Color(0xFFB9A5F8);
  static const lavenderLight = Color(0xFFD7CBFF);
  static const onLavender = Color(0xFF1A1438);

  // Accents.
  static const pdfRed = Color(0xFFF0434F);
  static const pdfRedDeep = Color(0xFFD81B45);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);
  static const star = Color(0xFFF59E0B);

  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9F7AFA), Color(0xFF6D28D9)],
  );

  static const lavenderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lavenderLight, lavender],
  );

  static const pdfGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pdfRed, pdfRedDeep],
  );
}

/// Theme-dependent colour tokens.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.codeText,
    required this.glowStrength,
    required this.textGradient,
  });

  /// Page background, darkest/lightest to the elevated layers.
  final Color background;
  final Color backgroundDeep;
  final Color surface;
  final Color surfaceHigh;
  final Color surfaceHighest;
  final Color border;
  final Color borderStrong;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Violet used for icons, links and highlights on surfaces.
  final Color accent;

  /// Text colour inside code blocks and inline code.
  final Color codeText;

  /// Multiplier for ambient glows/shadows (softer on light backgrounds).
  final double glowStrength;

  /// Gradient for the "Mind" part of the wordmark.
  final Gradient textGradient;

  static const dark = AppPalette(
    background: Color(0xFF0B0A18),
    backgroundDeep: Color(0xFF07060F),
    surface: Color(0xFF15132A),
    surfaceHigh: Color(0xFF1D1A38),
    surfaceHighest: Color(0xFF262248),
    border: Color(0xFF2A2650),
    borderStrong: Color(0xFF3A3470),
    textPrimary: Color(0xFFF4F2FF),
    textSecondary: Color(0xFFB0AACF),
    textMuted: Color(0xFF7A7499),
    accent: AppColors.lavender,
    codeText: AppColors.lavenderLight,
    glowStrength: 1,
    textGradient: LinearGradient(
      colors: [Color(0xFFC4B1FF), Color(0xFF9B6BFA)],
    ),
  );

  static const light = AppPalette(
    background: Color(0xFFF7F5FF),
    backgroundDeep: Color(0xFFEEEAFB),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF2EEFF),
    surfaceHighest: Color(0xFFE7E0FF),
    border: Color(0xFFE2DCF5),
    borderStrong: Color(0xFFCBC1EC),
    textPrimary: Color(0xFF15122B),
    textSecondary: Color(0xFF575173),
    textMuted: Color(0xFF8A84A6),
    accent: Color(0xFF6D28D9),
    codeText: Color(0xFF5B21B6),
    glowStrength: 0.45,
    textGradient: LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    ),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: c(background, other.background),
      backgroundDeep: c(backgroundDeep, other.backgroundDeep),
      surface: c(surface, other.surface),
      surfaceHigh: c(surfaceHigh, other.surfaceHigh),
      surfaceHighest: c(surfaceHighest, other.surfaceHighest),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      accent: c(accent, other.accent),
      codeText: c(codeText, other.codeText),
      glowStrength: glowStrength + (other.glowStrength - glowStrength) * t,
      textGradient: t < 0.5 ? textGradient : other.textGradient,
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// Current theme's colour tokens.
  AppPalette get colors => Theme.of(this).extension<AppPalette>()!;
}

/// Shared spacing and radius scale.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double gutter = 20;

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusPill = 100;
}

abstract final class AppTheme {
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: isDark ? AppColors.primaryDeep : p.surfaceHighest,
      onPrimaryContainer: isDark ? AppColors.lavenderLight : AppColors.primaryDeep,
      secondary: p.accent,
      onSecondary: isDark ? AppColors.onLavender : Colors.white,
      surface: p.background,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.backgroundDeep,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surfaceHigh,
      surfaceContainerHighest: p.surfaceHighest,
      outline: p.borderStrong,
      outlineVariant: p.border,
      error: AppColors.danger,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
    );

    final text = base.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.background,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(
          height: 1.5,
          color: p.textPrimary,
        ),
        bodySmall: text.bodySmall?.copyWith(color: p.textSecondary),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? p.surfaceHigh : p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shadowColor: AppColors.primaryDeep.withValues(alpha: isDark ? 0.6 : 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: p.border),
        ),
        textStyle: TextStyle(color: p.textPrimary, fontSize: 15),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? p.surfaceHigh : p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: p.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? p.surfaceHighest : p.textPrimary,
        contentTextStyle: TextStyle(color: isDark ? p.textPrimary : p.surface),
        actionTextColor: AppColors.lavender,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.25),
        selectionHandleColor: p.accent,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceHighest,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.accent),
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

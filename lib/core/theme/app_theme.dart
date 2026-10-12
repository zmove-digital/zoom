import 'package:flutter/material.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/category.dart';
import '../constants.dart';

class AppTheme {
  static ThemeData build(AppSettings settings, Brightness brightness) {
    final Color seed = _safeColor(settings.seedColorHex);
    final Color accent = _safeColor(settings.accentColorHex);

    ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    scheme = scheme.copyWith(
      secondary: accent,
      tertiary: accent,
    );

    final bool rounded = settings.useRoundedCards;
    final double radius = rounded ? 22 : 8;

    final ThemeData base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      fontFamily: 'Poppins',
    );

    return base.copyWith(
      textTheme: _scaleText(base.textTheme, settings.fontScale),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: withOpacity(scheme.surfaceContainerHighest, settings.cardOpacity),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: withOpacity(scheme.surfaceContainerHighest, settings.cardOpacity),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius * 0.7),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius * 0.7),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius * 0.6),
        ),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: withOpacity(seed, 0.18),
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: withOpacity(scheme.outline, 0.25)),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _scaleText(TextTheme base, double scale) {
    if (scale <= 1.0) return base;
    TextStyle? apply(TextStyle? style) =>
        style?.copyWith(fontSize: (style.fontSize ?? 14) * scale);
    return base.copyWith(
      displayLarge: apply(base.displayLarge),
      displayMedium: apply(base.displayMedium),
      displaySmall: apply(base.displaySmall),
      headlineLarge: apply(base.headlineLarge),
      headlineMedium: apply(base.headlineMedium),
      headlineSmall: apply(base.headlineSmall),
      titleLarge: apply(base.titleLarge),
      titleMedium: apply(base.titleMedium),
      titleSmall: apply(base.titleSmall),
      bodyLarge: apply(base.bodyLarge),
      bodyMedium: apply(base.bodyMedium),
      bodySmall: apply(base.bodySmall),
      labelLarge: apply(base.labelLarge),
      labelMedium: apply(base.labelMedium),
      labelSmall: apply(base.labelSmall),
    );
  }

  static Color _safeColor(String hex) {
    try {
      return colorFromHex(hex);
    } catch (_) {
      return kDefaultSeed;
    }
  }
}

Color withOpacity(Color color, double opacity) {
  return color.withValues(alpha: opacity.clamp(0.0, 1.0));
}

import 'package:flutter/material.dart';

/// Thème sobre : quotidien propre et épuré, une seule teinte d'accent, des surfaces
/// douces. La réussite fait exception et se fête fortement (`celebration.dart`).
/// Référence d'ambiance : Samewise (`docs/PLAN.md`).
class AppTheme {
  static const _seed = Color(0xFF4A7BD0);

  static ThemeData light() =>
      _build(ColorScheme.fromSeed(seedColor: _seed).copyWith(surface: const Color(0xFFF7F6F2)));

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(surface: const Color(0xFF16181C)),
  );

  static ThemeData _build(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.brightness == Brightness.light ? Colors.white : const Color(0xFF1F2227),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(160, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      textTheme: Typography.material2021().black.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
  }
}

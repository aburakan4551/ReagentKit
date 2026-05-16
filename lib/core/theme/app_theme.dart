import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  static ColorScheme _lightScheme() {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      error: AppColors.error,
    );
    return base.copyWith(
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightText,
      onSurfaceVariant: AppColors.lightTextSecondary,
      surfaceContainerLowest: AppColors.lightBackground,
      surfaceContainerLow: const Color(0xFFF1F5F9),
      surfaceContainer: const Color(0xFFE2E8F0),
      surfaceContainerHigh: const Color(0xFFFFFFFF),
      surfaceContainerHighest: const Color(0xFFFFFFFF),
      outline: AppColors.lightBorder,
      outlineVariant: const Color(0xFFCBD5E1),
      surfaceTint: Colors.transparent,
      shadow: const Color(0x66000000),
      scrim: Color(0x99000000),
    );
  }

  static ColorScheme _darkScheme() {
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      error: AppColors.error,
    );
    return base.copyWith(
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
      onSurfaceVariant: AppColors.darkTextSecondary,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
      surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
      primaryContainer: const Color(0xFF312E81),
      onPrimaryContainer: const Color(0xFFE0E7FF),
      secondaryContainer: const Color(0xFF831843),
      onSecondaryContainer: const Color(0xFFFCE7F3),
      tertiaryContainer: const Color(0xFF0F766E),
      onTertiaryContainer: const Color(0xFFCCFBF1),
      outline: AppColors.darkBorder,
      outlineVariant: const Color(0xFF475569),
      surfaceTint: Colors.transparent,
      shadow: const Color(0xE6000000),
      scrim: Color(0xCC000000),
    );
  }

  static ThemeData _baseTheme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color scaffoldBackground,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final TextTheme textTheme = TextTheme(
      displayLarge: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: colorScheme.onSurface),
      bodyMedium: TextStyle(color: colorScheme.onSurfaceVariant),
      labelLarge: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      shadowColor: colorScheme.shadow,
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant, thickness: 1),
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      textTheme: textTheme,
    );
  }

  static ThemeData get lightTheme {
    final ColorScheme scheme = _lightScheme();
    return _baseTheme(
      colorScheme: scheme,
      brightness: Brightness.light,
      scaffoldBackground: AppColors.lightBackground,
    );
  }

  static ThemeData get darkTheme {
    final ColorScheme scheme = _darkScheme();
    return _baseTheme(
      colorScheme: scheme,
      brightness: Brightness.dark,
      scaffoldBackground: AppColors.darkBackground,
    );
  }
}

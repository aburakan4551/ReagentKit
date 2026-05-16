import 'package:flutter/material.dart';

/// Brand and neutral tokens. Prefer [ColorScheme] in widgets; these back [AppTheme] only.
class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFFEC4899);
  static const Color accent = Color(0xFF14B8A6);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  /// Dark scaffold — slightly darker than cards for clear depth (iOS-like layering).
  static const Color darkBackground = Color(0xFF0B0F17);
  static const Color darkSurface = Color(0xFF121826);
  static const Color darkSurfaceContainer = Color(0xFF1A2230);
  static const Color darkSurfaceContainerHigh = Color(0xFF232C3D);
  static const Color darkSurfaceContainerHighest = Color(0xFF2D3748);
  static const Color darkText = Color(0xFFF1F5F9);
  /// WCAG-friendly on darkSurface (~7:1 vs surface).
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkBorder = Color(0xFF3D4A5C);

  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFF87171);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF60A5FA);
}

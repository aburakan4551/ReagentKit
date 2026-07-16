import 'package:flutter/material.dart';

/// A premium dark/light theme color palette optimized for iOS OLED displays and WCAG contrast.
class AppColors {
  // Backgrounds (Dark Theme / Legacy defaults)
  static const Color backgroundBase = Color(0xFF0B1020);
  static const Color backgroundElevated = Color(0xFF111827);
  static const Color backgroundHighest = Color(0xFF151B2E);

  // Surfaces (Cards, BottomNav, Dialogs)
  static const Color surfaceBase = Color(0xFF1A2238);
  static const Color surfaceElevated = Color(0xFF202A44);
  static const Color surfaceHighlight = Color(0xFF2A3655);

  // Accents
  static const Color primaryAccent = Color(0xFF7C5CFF);
  static const Color secondaryAccent = Color(0xFF5B8CFF);
  static const Color tertiaryAccent =
      Color(0xFFE879F9); // Optional soft pink/purple for premium

  // Typography
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFFC7CEDB);
  static const Color textMuted = Color(0xFF94A3B8);

  // Status & Semantic (Desaturated for premium feel)
  static const Color statusSuccess = Color(0xFF34D399); // Soft emerald
  static const Color statusWarning = Color(0xFFFBBF24); // Soft amber
  static const Color statusError = Color(0xFFF87171); // Soft red
  static const Color statusInfo = Color(0xFF60A5FA); // Soft blue

  // Rarities
  static const Color rarityCommon = textSecondary;
  static const Color rarityUncommon = statusSuccess;
  static const Color rarityRare = secondaryAccent;
  static const Color rarityEpic = primaryAccent;
  static const Color rarityLegendary = Color(0xFFF59E0B); // Gold

  // Borders & Dividers
  static const Color borderSubtle =
      Color(0xFF2A3655); // Slightly lighter than surfaceElevated
  static const Color borderHighlight = Color(0xFF3B4868);

  // Overlay / Blur Backgrounds
  static const Color overlayDark = Color(0x990B1020); // 60% opacity background
  static const Color overlayLight = Color(0x1AFFFFFF); // 10% white

  // ==========================================
  // Light Theme Color Palette
  // ==========================================

  // Backgrounds
  static const Color lightBackgroundBase =
      Color(0xFFF8F9FC); // Pure soft white/cool grey-white background
  static const Color lightBackgroundElevated = Colors.white; // Pure white
  static const Color lightBackgroundHighest =
      Color(0xFFF1F3F9); // Slight warm scientific gray surface

  // Surfaces (Cards, BottomNav, Dialogs)
  static const Color lightSurfaceBase = Colors.white;
  static const Color lightSurfaceElevated = Color(0xFFF8F9FC);
  static const Color lightSurfaceHighlight = Color(0xFFE6E8F0);

  // Accents (Enhanced contrast/vibrancy for light background)
  static const Color lightPrimaryAccent =
      Color(0xFF7C4DFF); // Indigo/violet accent
  static const Color lightSecondaryAccent = Color(0xFF3B82F6); // Vibrant Blue
  static const Color lightTertiaryAccent = Color(0xFFD946EF); // Magenta

  // Typography
  static const Color lightTextPrimary =
      Color(0xFF101828); // Accessible deep charcoal
  static const Color lightTextSecondary = Color(0xFF667085); // Secondary grey
  static const Color lightTextMuted = Color(0xFF94A3B8); // Muted grey

  // Status & Semantic
  static const Color lightStatusSuccess = Color(0xFF10B981); // Emerald
  static const Color lightStatusWarning = Color(0xFFD97706); // Deep amber
  static const Color lightStatusError = Color(0xFFEF4444); // Red
  static const Color lightStatusInfo = Color(0xFF2563EB); // Blue

  // Rarities
  static const Color lightRarityCommon = lightTextSecondary;
  static const Color lightRarityUncommon = lightStatusSuccess;
  static const Color lightRarityRare = lightSecondaryAccent;
  static const Color lightRarityEpic = lightPrimaryAccent;
  static const Color lightRarityLegendary = Color(0xFFD97706); // Dark gold

  // Borders & Dividers
  static const Color lightBorderSubtle = Color(0xFFE6E8F0); // Subtle border
  static const Color lightBorderHighlight = Color(0xFFD1D5DB);

  // Overlay / Blur Backgrounds
  static const Color lightOverlayDark = Color(0x1A000000); // 10% black
  static const Color lightOverlayLight = Color(0x0D000000); // 5% black
}

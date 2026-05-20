import 'package:flutter/material.dart';

/// A premium dark theme color palette optimized for iOS OLED displays and WCAG contrast.
class AppColors {
  // Backgrounds
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
  static const Color tertiaryAccent = Color(0xFFE879F9); // Optional soft pink/purple for premium

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
  static const Color borderSubtle = Color(0xFF2A3655); // Slightly lighter than surfaceElevated
  static const Color borderHighlight = Color(0xFF3B4868);

  // Overlay / Blur Backgrounds
  static const Color overlayDark = Color(0x990B1020); // 60% opacity background
  static const Color overlayLight = Color(0x1AFFFFFF); // 10% white
}

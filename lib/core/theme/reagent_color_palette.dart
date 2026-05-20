import 'package:flutter/material.dart';

/// Centralized, high-fidelity color palette mapping chemical reaction color names
/// to premium, harmonized Flutter Color swatches.
class ReagentColorPalette {
  ReagentColorPalette._();

  // Premium, balanced swatches (desaturated for modern dark mode aesthetics)
  static const Color obsidianBlack = Color(0xFF1E1E24);
  static const Color deepBlue = Color(0xFF1E40AF);
  static const Color electricBlue = Color(0xFF3B82F6);
  static const Color skyBlue = Color(0xFF60A5FA);
  static const Color forestGreen = Color(0xFF065F46);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color deepRed = Color(0xFF991B1B);
  static const Color roseRed = Color(0xFFEF4444);
  static const Color lightOrange = Color(0xFFFBBF24);
  static const Color amberOrange = Color(0xFFF59E0B);
  static const Color lightYellow = Color(0xFFFEF08A);
  static const Color brightYellow = Color(0xFFFDE047);
  static const Color royalPurple = Color(0xFF7C3AED);
  static const Color hotPink = Color(0xFFEC4899);
  static const Color woodBrown = Color(0xFF78350F);
  static const Color neutralGray = Color(0xFF6B7280);
  static const Color clearNone = Color(0xFFD1D5DB);

  /// Map containing English color names to UI Display colors
  static const Map<String, Color> colorMap = {
    'black': obsidianBlack,
    'dark blue': deepBlue,
    'bright blue': skyBlue,
    'blue': electricBlue,
    'bright green': emeraldGreen,
    'green': forestGreen,
    'dark red': deepRed,
    'red': roseRed,
    'light orange': lightOrange,
    'orange': amberOrange,
    'light yellow': lightYellow,
    'yellow': brightYellow,
    'purple': royalPurple,
    'pink': hotPink,
    'brown': woodBrown,
    'none': clearNone,
    'no change': clearNone,
    'clear': clearNone,
  };

  /// Get display color for any color name dynamically
  static Color getDisplayColor(String colorName) {
    final lowerColor = colorName.toLowerCase().trim();

    // Check direct map matches
    if (colorMap.containsKey(lowerColor)) {
      return colorMap[lowerColor]!;
    }

    // Fallback fuzzy checks
    if (lowerColor.contains('black')) return obsidianBlack;
    if (lowerColor.contains('blue') && lowerColor.contains('dark')) return deepBlue;
    if (lowerColor.contains('blue') && lowerColor.contains('bright')) return skyBlue;
    if (lowerColor.contains('blue')) return electricBlue;
    if (lowerColor.contains('green') && lowerColor.contains('bright')) return emeraldGreen;
    if (lowerColor.contains('green')) return forestGreen;
    if (lowerColor.contains('red') && lowerColor.contains('dark')) return deepRed;
    if (lowerColor.contains('red')) return roseRed;
    if (lowerColor.contains('orange') && lowerColor.contains('light')) return lightOrange;
    if (lowerColor.contains('orange')) return amberOrange;
    if (lowerColor.contains('yellow') && lowerColor.contains('light')) return lightYellow;
    if (lowerColor.contains('yellow')) return brightYellow;
    if (lowerColor.contains('purple')) return royalPurple;
    if (lowerColor.contains('pink')) return hotPink;
    if (lowerColor.contains('brown')) return woodBrown;
    if (lowerColor.contains('none') ||
        lowerColor.contains('no change') ||
        lowerColor.contains('clear')) {
      return clearNone;
    }

    return neutralGray;
  }
}

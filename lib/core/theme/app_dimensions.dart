import 'package:flutter/material.dart';

class AppDimensions {
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0; // Primary cards
  static const double radiusXLarge = 32.0;

  static final BorderRadius roundedSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius roundedMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius roundedLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius roundedXLarge = BorderRadius.circular(radiusXLarge);

  // Spacing (Responsive-ready margins/paddings)
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // Components
  static const double bottomNavHeight = 72.0;
  static const double buttonHeight = 56.0;
  static const double inputHeight = 56.0;
  static const double cardElevation = 0.0; // Use colors/borders instead of shadows for modern feel
  
  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  
  static EdgeInsets get screenPadding => const EdgeInsets.symmetric(horizontal: spacingLarge);
}

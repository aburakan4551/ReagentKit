import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // Consistent Weights
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  // Tuned Letter Spacings (iOS style)
  static const double trackingPageTitle = -0.5;
  static const double trackingSectionTitle = -0.3;
  static const double trackingCardTitle = -0.2;
  static const double trackingBody = 0.0;
  static const double trackingLabel = 0.1;
  static const double trackingCaption = 0.2;

  // Base font sizes
  static const double sizePageTitle = 32.0;
  static const double sizeSectionTitle = 22.0;
  static const double sizeCardTitle = 18.0;
  static const double sizeMetadataValue = 15.0;
  static const double sizeMetadataLabel = 13.0;
  static const double sizeCaption = 12.0;

  /// Get native-looking, responsive typography for the current context.
  /// Scaled font sizes automatically respect the system's text scale settings.
  static TextStyle getPageTitle(BuildContext context, {Color? color}) {
    final textScaler = MediaQuery.textScalerOf(context);
    return _baseStyle(
      fontSize: textScaler.scale(sizePageTitle),
      fontWeight: bold,
      letterSpacing: trackingPageTitle,
      height: 1.2,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle getSectionTitle(BuildContext context, {Color? color}) {
    final textScaler = MediaQuery.textScalerOf(context);
    return _baseStyle(
      fontSize: textScaler.scale(sizeSectionTitle),
      fontWeight: bold,
      letterSpacing: trackingSectionTitle,
      height: 1.3,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle getCardTitle(BuildContext context, {Color? color}) {
    final textScaler = MediaQuery.textScalerOf(context);
    return _baseStyle(
      fontSize: textScaler.scale(sizeCardTitle),
      fontWeight: semiBold,
      letterSpacing: trackingCardTitle,
      height: 1.35,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle getMetadataValue(BuildContext context, {Color? color}) {
    final textScaler = MediaQuery.textScalerOf(context);
    return _baseStyle(
      fontSize: textScaler.scale(sizeMetadataValue),
      fontWeight: medium,
      letterSpacing: trackingBody,
      height: 1.4,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle getMetadataLabel(BuildContext context, {Color? color, bool isBold = false}) {
    final textScaler = MediaQuery.textScalerOf(context);
    return _baseStyle(
      fontSize: textScaler.scale(sizeMetadataLabel),
      fontWeight: isBold ? bold : regular,
      letterSpacing: trackingLabel,
      height: 1.4,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle getCaption(BuildContext context, {Color? color}) {
    final textScaler = MediaQuery.textScalerOf(context);
    return _baseStyle(
      fontSize: textScaler.scale(sizeCaption),
      fontWeight: regular,
      letterSpacing: trackingCaption,
      height: 1.4,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle _baseStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double letterSpacing,
    required double height,
    required Color color,
  }) {
    // SF Pro / Inter display style
    // On iOS it will use the default system font if we use TextStyle without a fontFamily.
    // To maintain a premium look across all platforms (Android/iOS/Web), we use GoogleFonts.inter.
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }
}

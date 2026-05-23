import 'package:flutter/material.dart';
import '../app_colors.dart';

class PremiumCardTheme extends ThemeExtension<PremiumCardTheme> {
  final Color background;
  final Color iconColor;
  final Color textColor;
  final List<Color> gradientColors;

  const PremiumCardTheme({
    required this.background,
    required this.iconColor,
    required this.textColor,
    required this.gradientColors,
  });

  @override
  ThemeExtension<PremiumCardTheme> copyWith({
    Color? background,
    Color? iconColor,
    Color? textColor,
    List<Color>? gradientColors,
  }) {
    return PremiumCardTheme(
      background: background ?? this.background,
      iconColor: iconColor ?? this.iconColor,
      textColor: textColor ?? this.textColor,
      gradientColors: gradientColors ?? this.gradientColors,
    );
  }

  @override
  ThemeExtension<PremiumCardTheme> lerp(ThemeExtension<PremiumCardTheme>? other, double t) {
    if (other is! PremiumCardTheme) return this;
    
    // For lists we just take the nearest if not matching size, but here we assume fixed sizes.
    final gColors = <Color>[];
    for (int i = 0; i < gradientColors.length; i++) {
      if (i < other.gradientColors.length) {
        gColors.add(Color.lerp(gradientColors[i], other.gradientColors[i], t)!);
      } else {
        gColors.add(gradientColors[i]);
      }
    }

    return PremiumCardTheme(
      background: Color.lerp(background, other.background, t)!,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      gradientColors: gColors,
    );
  }

  static PremiumCardTheme get dark => PremiumCardTheme(
    background: AppColors.surfaceElevated,
    iconColor: AppColors.primaryAccent,
    textColor: Colors.white,
    gradientColors: [
      AppColors.primaryAccent.withValues(alpha: 0.15),
      AppColors.secondaryAccent.withValues(alpha: 0.15),
    ],
  );
  
  static PremiumCardTheme get light => PremiumCardTheme(
    background: AppColors.lightSurfaceBase,
    iconColor: AppColors.lightPrimaryAccent,
    textColor: AppColors.lightTextPrimary,
    gradientColors: [
      AppColors.lightPrimaryAccent.withValues(alpha: 0.08),
      AppColors.lightSecondaryAccent.withValues(alpha: 0.08),
    ],
  );
}

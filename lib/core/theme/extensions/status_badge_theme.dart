import 'package:flutter/material.dart';
import '../app_colors.dart';

class StatusBadgeTheme extends ThemeExtension<StatusBadgeTheme> {
  final Color successBg;
  final Color successText;
  final Color warningBg;
  final Color warningText;
  final Color errorBg;
  final Color errorText;
  final Color infoBg;
  final Color infoText;

  const StatusBadgeTheme({
    required this.successBg,
    required this.successText,
    required this.warningBg,
    required this.warningText,
    required this.errorBg,
    required this.errorText,
    required this.infoBg,
    required this.infoText,
  });

  @override
  ThemeExtension<StatusBadgeTheme> copyWith({
    Color? successBg,
    Color? successText,
    Color? warningBg,
    Color? warningText,
    Color? errorBg,
    Color? errorText,
    Color? infoBg,
    Color? infoText,
  }) {
    return StatusBadgeTheme(
      successBg: successBg ?? this.successBg,
      successText: successText ?? this.successText,
      warningBg: warningBg ?? this.warningBg,
      warningText: warningText ?? this.warningText,
      errorBg: errorBg ?? this.errorBg,
      errorText: errorText ?? this.errorText,
      infoBg: infoBg ?? this.infoBg,
      infoText: infoText ?? this.infoText,
    );
  }

  @override
  ThemeExtension<StatusBadgeTheme> lerp(ThemeExtension<StatusBadgeTheme>? other, double t) {
    if (other is! StatusBadgeTheme) return this;
    return StatusBadgeTheme(
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      errorBg: Color.lerp(errorBg, other.errorBg, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
    );
  }

  static StatusBadgeTheme get dark => StatusBadgeTheme(
    successBg: AppColors.statusSuccess.withValues(alpha: 0.15),
    successText: AppColors.statusSuccess,
    warningBg: AppColors.statusWarning.withValues(alpha: 0.15),
    warningText: AppColors.statusWarning,
    errorBg: AppColors.statusError.withValues(alpha: 0.15),
    errorText: AppColors.statusError,
    infoBg: AppColors.statusInfo.withValues(alpha: 0.15),
    infoText: AppColors.statusInfo,
  );
  
  static StatusBadgeTheme get light => StatusBadgeTheme(
    successBg: AppColors.lightStatusSuccess.withValues(alpha: 0.1),
    successText: AppColors.lightStatusSuccess,
    warningBg: AppColors.lightStatusWarning.withValues(alpha: 0.1),
    warningText: AppColors.lightStatusWarning,
    errorBg: AppColors.lightStatusError.withValues(alpha: 0.1),
    errorText: AppColors.lightStatusError,
    infoBg: AppColors.lightStatusInfo.withValues(alpha: 0.1),
    infoText: AppColors.lightStatusInfo,
  );
}

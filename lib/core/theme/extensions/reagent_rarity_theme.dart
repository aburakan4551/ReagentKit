import 'package:flutter/material.dart';
import '../app_colors.dart';

class ReagentRarityTheme extends ThemeExtension<ReagentRarityTheme> {
  final Color commonColor;
  final Color uncommonColor;
  final Color rareColor;
  final Color epicColor;
  final Color legendaryColor;

  const ReagentRarityTheme({
    required this.commonColor,
    required this.uncommonColor,
    required this.rareColor,
    required this.epicColor,
    required this.legendaryColor,
  });

  @override
  ThemeExtension<ReagentRarityTheme> copyWith({
    Color? commonColor,
    Color? uncommonColor,
    Color? rareColor,
    Color? epicColor,
    Color? legendaryColor,
  }) {
    return ReagentRarityTheme(
      commonColor: commonColor ?? this.commonColor,
      uncommonColor: uncommonColor ?? this.uncommonColor,
      rareColor: rareColor ?? this.rareColor,
      epicColor: epicColor ?? this.epicColor,
      legendaryColor: legendaryColor ?? this.legendaryColor,
    );
  }

  @override
  ThemeExtension<ReagentRarityTheme> lerp(ThemeExtension<ReagentRarityTheme>? other, double t) {
    if (other is! ReagentRarityTheme) return this;
    return ReagentRarityTheme(
      commonColor: Color.lerp(commonColor, other.commonColor, t)!,
      uncommonColor: Color.lerp(uncommonColor, other.uncommonColor, t)!,
      rareColor: Color.lerp(rareColor, other.rareColor, t)!,
      epicColor: Color.lerp(epicColor, other.epicColor, t)!,
      legendaryColor: Color.lerp(legendaryColor, other.legendaryColor, t)!,
    );
  }

  static ReagentRarityTheme get dark => const ReagentRarityTheme(
    commonColor: AppColors.rarityCommon,
    uncommonColor: AppColors.rarityUncommon,
    rareColor: AppColors.rarityRare,
    epicColor: AppColors.rarityEpic,
    legendaryColor: AppColors.rarityLegendary,
  );
  
  static ReagentRarityTheme get light => const ReagentRarityTheme(
    commonColor: AppColors.rarityCommon,
    uncommonColor: AppColors.rarityUncommon,
    rareColor: AppColors.rarityRare,
    epicColor: AppColors.rarityEpic,
    legendaryColor: AppColors.rarityLegendary,
  );
}

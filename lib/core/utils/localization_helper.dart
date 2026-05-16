import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../features/reagent_testing/domain/entities/reagent_entity.dart';
import '../../features/reagent_testing/domain/entities/drug_result_entity.dart';

class LocalizationHelper {
  static String getLocalizedReagentName(
    BuildContext context,
    ReagentEntity reagent,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic && reagent.reagentNameAr.isNotEmpty
        ? reagent.reagentNameAr
        : reagent.reagentName;
  }

  static String getLocalizedDescription(
    BuildContext context,
    ReagentEntity reagent,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic && reagent.descriptionAr.isNotEmpty
        ? reagent.descriptionAr
        : reagent.description;
  }

  static String getLocalizedSafetyLevel(
    BuildContext context,
    ReagentEntity reagent,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic && reagent.safetyLevelAr.isNotEmpty
        ? reagent.safetyLevelAr
        : reagent.safetyLevel;
  }

  static String getLocalizedDrugColor(
    BuildContext context,
    DrugResultEntity drugResult,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic && drugResult.colorAr.isNotEmpty
        ? drugResult.colorAr
        : drugResult.color;
  }

  static String getLocalizedSafetyLevelTranslation(
    BuildContext context,
    String safetyLevel,
  ) {
    final l10n = AppLocalizations.of(context)!;
    switch (safetyLevel.toLowerCase()) {
      case 'high':
        return l10n.high;
      case 'medium':
        return l10n.medium;
      case 'low':
        return l10n.low;
      case 'extreme':
        return l10n.extreme;
      default:
        return safetyLevel;
    }
  }

  static String getLocalizedColorTranslation(
    BuildContext context,
    String color,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (color.toLowerCase().contains('no color change') ||
        color.toLowerCase().contains('no change')) {
      return l10n.noColorChange;
    }
    return color;
  }

  static bool isRTL(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  static IconData getBackChevronIcon(BuildContext context) {
    return isRTL(context) ? HeroIcons.chevron_right : HeroIcons.chevron_left;
  }
}

import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../domain/entities/reagent_entity.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../../core/theme/extensions/status_badge_theme.dart';
import '../../../../core/widgets/auto_size_text.dart';

class ReagentCard extends StatelessWidget {
  final ReagentEntity reagent;
  final VoidCallback? onTap;

  const ReagentCard({super.key, required this.reagent, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              Expanded(child: _buildDescription(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoSizeText(
                LocalizationHelper.getLocalizedReagentName(context, reagent),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
                maxLines: 2,
                minFontSize: 12,
                stepGranularity: 0.5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 6),
              _buildSafetyBadge(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(BuildContext context) {
    final statusTheme = Theme.of(context).extension<StatusBadgeTheme>() ?? StatusBadgeTheme.dark;
    Color iconBackgroundColor;
    Color iconColor;
    
    switch (reagent.safetyLevel.toUpperCase()) {
      case 'EXTREME':
        iconBackgroundColor = statusTheme.errorBg;
        iconColor = statusTheme.errorText;
        break;
      case 'HIGH':
        iconBackgroundColor = statusTheme.warningBg;
        iconColor = statusTheme.warningText;
        break;
      case 'MEDIUM':
        iconBackgroundColor = statusTheme.infoBg;
        iconColor = statusTheme.infoText;
        break;
      default:
        iconBackgroundColor = statusTheme.successBg;
        iconColor = statusTheme.successText;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        HeroIcons.beaker, // Chemistry beaker icon for reagent cards
        color: iconColor,
        size: 28,
      ),
    );
  }

  Widget _buildSafetyBadge(BuildContext context) {
    final statusTheme = Theme.of(context).extension<StatusBadgeTheme>() ?? StatusBadgeTheme.dark;
    Color badgeBgColor;
    Color badgeTextColor;
    String level = reagent.safetyLevel.toUpperCase();

    switch (level) {
      case 'HIGH':
        badgeBgColor = statusTheme.warningBg;
        badgeTextColor = statusTheme.warningText;
        break;
      case 'EXTREME':
        badgeBgColor = statusTheme.errorBg;
        badgeTextColor = statusTheme.errorText;
        break;
      case 'MEDIUM':
        badgeBgColor = statusTheme.infoBg;
        badgeTextColor = statusTheme.infoText;
        break;
      case 'LOW':
      default:
        badgeBgColor = statusTheme.successBg;
        badgeTextColor = statusTheme.successText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        LocalizationHelper.getLocalizedSafetyLevelTranslation(context, level),
        style: TextStyle(
          color: badgeTextColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      LocalizationHelper.getLocalizedDescription(context, reagent),
      style: Theme.of(context).textTheme.bodySmall,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

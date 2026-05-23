import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/localization_helper.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/auto_size_text.dart';

class ReagentHeaderCard extends StatelessWidget {
  final ReagentEntity reagent;

  const ReagentHeaderCard({super.key, required this.reagent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2A3655)
              : const Color(0xFFE6E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReagentInfo(context, theme),
            const SizedBox(height: 16),
            _buildMetadataChips(context, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildReagentInfo(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        _buildIcon(theme),
        const SizedBox(width: 16),
        Expanded(child: _buildTextContent(context, theme)),
      ],
    );
  }

  Widget _buildIcon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        HeroIcons.beaker, // Chemistry beaker icon for reagent testing
        color: theme.colorScheme.primary,
        size: 28,
      ),
    );
  }

  Widget _buildTextContent(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          LocalizationHelper.getLocalizedReagentName(context, reagent),
          maxLines: 2,
          minFontSize: 12,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.getSectionTitle(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          LocalizationHelper.getLocalizedDescription(context, reagent),
          style: AppTypography.getMetadataValue(context,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataChips(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        _buildMetadataChip(
          context,
          theme,
          HeroIcons.clock, // Duration icon from HeroIcons
          l10n.duration(reagent.testDuration.toString()),
        ),
        const SizedBox(height: 8),
        _buildMetadataChip(
          context,
          theme,
          HeroIcons.tag, // Category icon from HeroIcons
          '${l10n.category}: ${_translateCategory(reagent.category, l10n)}',
        ),
      ],
    );
  }

  Widget _buildMetadataChip(BuildContext context, ThemeData theme, IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.getCaption(context,
                color: theme.colorScheme.onSurfaceVariant,
              ).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _translateCategory(String categoryValue, AppLocalizations l10n) {
    switch (categoryValue.toLowerCase()) {
      case 'primary tests':
        return l10n.primaryTests;
      case 'secondary tests':
        return l10n.secondaryTests;
      case 'specialized tests':
        return l10n.specializedTests;
      default:
        return categoryValue;
    }
  }
}

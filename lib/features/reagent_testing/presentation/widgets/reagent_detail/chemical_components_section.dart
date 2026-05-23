import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_typography.dart';

class ChemicalComponentsSection extends StatelessWidget {
  final ReagentEntity reagent;

  const ChemicalComponentsSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, theme, l10n),
        const SizedBox(height: 16),
        _buildChemicalsList(theme),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            HeroIcons.beaker, // Chemistry beaker icon for chemical components
            color: theme.colorScheme.secondary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.chemicalComponents,
          style: AppTypography.getSectionTitle(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChemicalsList(ThemeData theme) {
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
          children: reagent.chemicals
              .map((chemical) => _ChemicalItem(chemical: chemical))
              .toList(),
        ),
      ),
    );
  }
}

class _ChemicalItem extends StatelessWidget {
  final String chemical;

  const _ChemicalItem({required this.chemical});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            HeroIcons.check_circle, // Better bullet point icon
            size: 12,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(chemical, style: AppTypography.getMetadataValue(context))),
        ],
      ),
    );
  }
}

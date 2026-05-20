import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/services/safety_instructions_service.dart';
import '../../providers/reagent_testing_providers.dart';

enum SafetyIconType { equipment, procedures, hazards, storage }

class SafetyInformationSection extends ConsumerWidget {
  final ReagentEntity reagent;

  const SafetyInformationSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, l10n),
        const SizedBox(height: 16),
        _SafetyDetailsCard(reagent: reagent),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            HeroIcons.exclamation_triangle, // Safety warning icon
            color: theme.colorScheme.error,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.safetyInformation,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SafetyDetailsCard extends ConsumerWidget {
  final ReagentEntity reagent;

  const _SafetyDetailsCard({required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final safetyService = ref.read(safetyInstructionsServiceProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<SafetyData>(
          future: _loadSafetyData(safetyService, reagent.reagentName, isArabic),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingState();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _ErrorState(l10n: l10n, theme: theme);
            }

            return _SafetyContent(safetyData: snapshot.data!, l10n: l10n);
          },
        ),
      ),
    );
  }

  Future<SafetyData> _loadSafetyData(
    SafetyInstructionsService safetyService,
    String reagentName,
    bool isArabic,
  ) async {
    final results = await Future.wait<List<String>>([
      safetyService.getEquipmentForReagent(reagentName, isArabic: isArabic),
      safetyService.getHandlingProceduresForReagent(
        reagentName,
        isArabic: isArabic,
      ),
      safetyService.getSpecificHazardsForReagent(
        reagentName,
        isArabic: isArabic,
      ),
      safetyService.getStorageForReagent(reagentName, isArabic: isArabic),
    ]);

    return SafetyData(
      equipment: results[0],
      handlingProcedures: results[1],
      specificHazards: results[2],
      storage: results[3],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;

  const _ErrorState({required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(HeroIcons.exclamation_triangle, color: theme.colorScheme.error),
        const SizedBox(height: 8),
        Text(
          l10n.errorLoadingSettings,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ],
    );
  }
}

class _SafetyContent extends StatelessWidget {
  final SafetyData safetyData;
  final AppLocalizations l10n;

  const _SafetyContent({required this.safetyData, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SafetySection(
          title: l10n.equipment,
          items: safetyData.equipment,
          iconType: SafetyIconType.equipment,
        ),
        const SizedBox(height: 16),
        _SafetySection(
          title: l10n.handlingProcedures,
          items: safetyData.handlingProcedures,
          iconType: SafetyIconType.procedures,
        ),
        const SizedBox(height: 16),
        _SafetySection(
          title: l10n.specificHazards,
          items: safetyData.specificHazards,
          iconType: SafetyIconType.hazards,
        ),
        const SizedBox(height: 16),
        _SafetySection(
          title: l10n.storage,
          items: safetyData.storage,
          iconType: SafetyIconType.storage,
        ),
      ],
    );
  }
}

class _SafetySection extends StatelessWidget {
  final String title;
  final List<String> items;
  final SafetyIconType iconType;

  const _SafetySection({
    required this.title,
    required this.items,
    required this.iconType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _getIconWidget(context, iconType),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _SafetyItem(item: item)),
      ],
    );
  }

  Widget _getIconWidget(BuildContext context, SafetyIconType iconType) {
    final color = Theme.of(context).colorScheme.primary;
    switch (iconType) {
      case SafetyIconType.equipment:
        return Icon(HeroIcons.shield_check, size: 24, color: color);
      case SafetyIconType.procedures:
        return Icon(
          HeroIcons.wrench_screwdriver,
          size: 24,
          color: color,
        );
      case SafetyIconType.hazards:
        return Icon(
          HeroIcons.exclamation_triangle,
          size: 24,
          color: Theme.of(context).colorScheme.error,
        );
      case SafetyIconType.storage:
        return Icon(HeroIcons.archive_box, size: 24, color: color);
    }
  }
}

class _SafetyItem extends StatelessWidget {
  final String item;

  const _SafetyItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class SafetyData {
  final List<String> equipment;
  final List<String> handlingProcedures;
  final List<String> specificHazards;
  final List<String> storage;

  const SafetyData({
    required this.equipment,
    required this.handlingProcedures,
    required this.specificHazards,
    required this.storage,
  });
}

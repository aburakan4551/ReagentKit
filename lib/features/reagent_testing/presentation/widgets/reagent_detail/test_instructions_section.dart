import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../providers/reagent_testing_providers.dart';
import '../../../../../core/theme/app_typography.dart';

class TestInstructionsSection extends ConsumerWidget {
  final ReagentEntity reagent;

  const TestInstructionsSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, l10n),
        const SizedBox(height: 16),
        _InstructionsCard(reagent: reagent),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            HeroIcons.clipboard_document_list, // Test instructions icon
            color: theme.colorScheme.tertiary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.testInstructions,
          style: AppTypography.getSectionTitle(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InstructionsCard extends ConsumerWidget {
  final ReagentEntity reagent;

  const _InstructionsCard({required this.reagent});

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
        side: BorderSide(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2A3655)
              : const Color(0xFFE6E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<String>>(
          future: safetyService.getInstructionsForReagent(
            reagent.reagentName,
            isArabic: isArabic,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingState();
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return _ErrorState(l10n: l10n, theme: theme);
            }

            return _InstructionsList(instructions: snapshot.data!);
          },
        ),
      ),
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

class _InstructionsList extends StatelessWidget {
  final List<String> instructions;

  const _InstructionsList({required this.instructions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: instructions
          .asMap()
          .entries
          .map(
            (entry) => _InstructionItem(
              stepNumber: entry.key + 1,
              instruction: entry.value,
            ),
          )
          .toList(),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final int stepNumber;
  final String instruction;

  const _InstructionItem({required this.stepNumber, required this.instruction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepNumber(theme),
          const SizedBox(width: 12),
          Expanded(child: Text(instruction, style: AppTypography.getMetadataValue(context))),
        ],
      ),
    );
  }

  Widget _buildStepNumber(ThemeData theme) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$stepNumber',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

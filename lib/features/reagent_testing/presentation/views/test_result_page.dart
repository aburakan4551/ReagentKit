import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:reagentkit/core/theme/app_colors.dart';
import 'package:reagentkit/features/reagent_testing/domain/entities/test_result_entity.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:reagentkit/features/reagent_testing/presentation/states/test_result_state.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/localization_helper.dart';
import 'package:share_plus/share_plus.dart';

class TestResultPage extends ConsumerWidget {
  const TestResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testResultControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.testResults),
        leading: IconButton(
          icon: Icon(LocalizationHelper.getBackChevronIcon(context)),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          tooltip: l10n.backToHome,
        ),
        actions: [
          IconButton(
            icon: Icon(HeroIcons.share, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              if (state is TestResultLoaded) {
                final result = state.testResult;
                final substances = result.possibleSubstances.isNotEmpty
                    ? result.possibleSubstances.join(', ')
                    : l10n.unknownSubstance;
                
                final text = '🧪 ${l10n.testResult}:\n'
                    '${l10n.reagent}: ${result.reagentName}\n'
                    '${l10n.confidence}: ${result.confidencePercentage}%\n'
                    '${l10n.possibleSubstances}: $substances\n'
                    '${l10n.observedColorLabel}: ${result.observedColor}';
                
                Share.share(text, subject: l10n.testResult);
              }
            },
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: _buildBody(context, state, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TestResultState state,
    AppLocalizations l10n,
  ) {
    if (state is TestResultLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is TestResultLoaded) {
      return _ModernResultView(testResult: state.testResult);
    } else if (state is TestResultError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(HeroIcons.exclamation_circle, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(
                l10n.error(state.message),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.goBack),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(child: Text(l10n.noTestResultsYet));
    }
  }
}

class _ModernResultView extends StatelessWidget {
  final TestResultEntity testResult;

  const _ModernResultView({required this.testResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confidence = testResult.confidencePercentage / 100.0;
    final confidenceColor = _getConfidenceColor(context, testResult.confidencePercentage);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 1. Confidence Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.surfaceContainerLowest,
                        0.35,
                      ) ??
                      theme.colorScheme.surfaceContainerLowest,
                  theme.colorScheme.surfaceContainerLowest,
                ],
              ),
            ),
            child: Column(
              children: [
                CircularPercentIndicator(
                  radius: 80.0,
                  lineWidth: 12.0,
                  animation: true,
                  percent: confidence,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${testResult.confidencePercentage}%",
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: confidenceColor,
                        ),
                      ),
                      Text(
                        l10n.confidence,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: confidenceColor,
                  backgroundColor: confidenceColor.withOpacity(0.1),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  testResult.reagentName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
              ],
            ),
          ),

          // 2. Main Result Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel(context, l10n.possibleSubstances, HeroIcons.magnifying_glass),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      ...testResult.possibleSubstances.map((substance) => _SubstanceItem(substance: substance)),
                      if (testResult.possibleSubstances.isEmpty)
                        Text(
                          l10n.unknownSubstance,
                          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).moveX(begin: -20, end: 0),

                const SizedBox(height: 32),

                // 3. Observations
                _buildSectionLabel(context, l10n.observedColor, HeroIcons.eye),
                const SizedBox(height: 12),
                _ResultDetailTile(
                  label: l10n.observedColor,
                  value: testResult.observedColor,
                  icon: HeroIcons.swatch,
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 16),

                if (testResult.notes != null && testResult.notes!.isNotEmpty) ...[
                  _buildSectionLabel(context, l10n.notes, HeroIcons.pencil_square),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      testResult.notes!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 32),
                ],

                // 4. Analysis Logic / AI Reasoning (if any)
                if (testResult.notes?.contains('AI Analysis') ?? false)
                  _buildAIReasoningSection(context, l10n),

                const SizedBox(height: 48),

                // Actions
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(240, 56),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 2,
                      shadowColor: theme.colorScheme.shadow,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      l10n.backToHome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms).scale(duration: 400.ms),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final Color accent = theme.colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: accent,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAIReasoningSection(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(context, l10n.analysisIntelligenceTitle, HeroIcons.cpu_chip),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(HeroIcons.sparkles, color: theme.colorScheme.tertiary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.analysisIntelligenceDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  Color _getConfidenceColor(BuildContext context, int confidence) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (confidence >= 80) {
      return AppColors.success;
    }
    if (confidence >= 50) {
      return AppColors.warning;
    }
    return scheme.error;
  }
}

class _SubstanceItem extends StatelessWidget {
  final String substance;
  const _SubstanceItem({required this.substance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(HeroIcons.beaker, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              substance,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Icon(HeroIcons.chevron_right, size: 16, color: theme.colorScheme.outline),
        ],
      ),
    );
  }
}

class _ResultDetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ResultDetailTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:reagentkit/features/reagent_testing/domain/entities/test_result_entity.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:reagentkit/features/reagent_testing/presentation/states/test_result_state.dart';
import 'package:reagentkit/features/settings/presentation/providers/settings_providers.dart';
import 'package:reagentkit/scientific_engine/reference_parser.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/localization_helper.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:reagentkit/core/services/safe_store_sanitizer.dart';

// Provider to fetch references dynamically for a given reagent name
final reagentReferencesProvider = FutureProvider.family<List<String>, String>((ref, reagentName) async {
  final dataService = ref.watch(unifiedDataServiceProvider);
  final reagent = await dataService.getReagentByName(reagentName);
  return reagent?.references ?? [];
});

class TestResultPage extends ConsumerWidget {
  const TestResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testResultControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.testResults,
          style: AppTypography.getCardTitle(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LocalizationHelper.getBackChevronIcon(context)),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          tooltip: l10n.backToHome,
        ),
        actions: [
          if (state is TestResultLoaded)
            IconButton(
              icon: const Icon(HeroIcons.share),
              onPressed: () {
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
              },
            ),
        ],
      ),
      body: _buildBody(context, state, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TestResultState state,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    if (state is TestResultLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (state is TestResultLoaded) {
      return _ModernResultView(testResult: state.testResult);
    } else if (state is TestResultError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(HeroIcons.exclamation_circle, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                l10n.error(state.message),
                textAlign: TextAlign.center,
                style: AppTypography.getMetadataValue(context).copyWith(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.goBack),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Text(
          l10n.noTestResultsYet,
          style: AppTypography.getMetadataLabel(context),
        ),
      );
    }
  }
}

class _ModernResultView extends ConsumerWidget {
  final TestResultEntity testResult;

  const _ModernResultView({required this.testResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isResearchMode = ref.watch(researchModeEnabledProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final rc = ref.watch(remoteConfigServiceProvider);

    final reagentName = SafeStoreSanitizer.sanitize(
      isAr ? (testResult.reagentName == 'Marquis Test' ? 'اختبار ماركيز' : testResult.reagentName) : testResult.reagentName,
      isArabic: isAr,
    );

    final possibleSubstances = testResult.possibleSubstances.map((substance) {
      return SafeStoreSanitizer.sanitize(substance, isArabic: isAr);
    }).toList();

    final notes = testResult.notes != null
        ? SafeStoreSanitizer.sanitize(testResult.notes!, isArabic: isAr)
        : null;

    final observedColor = SafeStoreSanitizer.sanitize(testResult.observedColor, isArabic: isAr);

    final stabilityVal = testResult.stabilityIndex ?? 1.0;
    String stabilityText = isAr ? 'مستقر' : 'Stable Result';
    Color stabilityColor = theme.brightness == Brightness.dark 
        ? AppColors.statusSuccess 
        : AppColors.lightStatusSuccess;
    if (stabilityVal < 0.6) {
      stabilityText = isAr ? 'غير مستقر' : 'Unstable Interpretation';
      stabilityColor = theme.brightness == Brightness.dark 
          ? AppColors.statusError 
          : AppColors.lightStatusError;
    } else if (stabilityVal < 0.85) {
      stabilityText = isAr ? 'مستقر جزئياً' : 'Moderately Stable';
      stabilityColor = theme.brightness == Brightness.dark 
          ? AppColors.statusWarning 
          : AppColors.lightStatusWarning;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: theme.brightness == Brightness.dark
                    ? [
                        theme.colorScheme.surface.withValues(alpha: 0.8),
                        theme.scaffoldBackgroundColor,
                      ]
                    : [
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        theme.colorScheme.surface,
                      ],
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildConfidenceIndicator(
                      context,
                      percentage: testResult.aiInterpretationConfidence ?? (testResult.confidencePercentage / 100.0),
                      label: isAr ? 'ثقة تفسير الذكاء الاصطناعي' : 'AI Interpretation',
                      accentColor: theme.colorScheme.primary,
                    ),
                    _buildConfidenceIndicator(
                      context,
                      percentage: testResult.colorMatchConfidence ?? (testResult.confidencePercentage / 100.0),
                      label: isAr ? 'ثقة مطابقة اللون' : 'Color Match',
                      accentColor: theme.colorScheme.secondary,
                    ),
                  ],
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  reagentName,
                  style: AppTypography.getSectionTitle(context).copyWith(
                    letterSpacing: 1.1,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: stabilityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${isAr ? "مؤشر الاستقرار" : "Stability Index"}: $stabilityText (${(stabilityVal * 100).toInt()}%)',
                      style: AppTypography.getMetadataLabel(context,
                        color: theme.colorScheme.onSurfaceVariant,
                        isBold: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel(context, isAr ? 'تفسير الذكاء الاصطناعي' : 'AI Interpretation', HeroIcons.cpu_chip),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.brightness == Brightness.dark
                            ? Colors.transparent
                            : theme.colorScheme.shadow.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'المركبات المحتملة المرصودة:' : 'Possible Substances Detected:',
                        style: AppTypography.getMetadataLabel(context,
                          color: theme.colorScheme.onSurfaceVariant,
                          isBold: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...possibleSubstances.map((substance) => _SubstanceItem(substance: substance)),
                      if (possibleSubstances.isEmpty)
                        Text(
                          l10n.unknownSubstance,
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? AppColors.statusError
                                : AppColors.lightStatusError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (notes != null && notes.isNotEmpty) ...[
                        Divider(
                          color: theme.dividerColor,
                          height: 24,
                        ),
                        Text(
                          isAr ? 'التفاصيل والتحليل:' : 'Analysis Details:',
                          style: AppTypography.getMetadataLabel(context,
                            color: theme.colorScheme.onSurfaceVariant,
                            isBold: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notes,
                          style: AppTypography.getMetadataValue(context).copyWith(
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 24),
                _buildSectionLabel(context, isAr ? 'الملاحظة البصرية اليدوية' : 'Manual Observation', HeroIcons.eye),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.brightness == Brightness.dark
                            ? Colors.transparent
                            : theme.colorScheme.shadow.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _parseHexColor(testResult.observedHex, observedColor),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.dividerColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'اللون المرصود بالتحليل' : 'Observed Color Reaction',
                              style: AppTypography.getMetadataLabel(context,
                                color: theme.colorScheme.onSurfaceVariant,
                                isBold: true,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              observedColor,
                              style: AppTypography.getCardTitle(context).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),
                if (isResearchMode) ...[
                  _buildSectionLabel(context, isAr ? 'تفاصيل المحرك العلمي للبحث' : 'Scientific Research Data', HeroIcons.beaker),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.brightness == Brightness.dark
                              ? Colors.transparent
                              : theme.colorScheme.shadow.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(1.8),
                      },
                      children: [
                        _buildTableRow(context, isAr ? 'قيمة اللون HEX:' : 'HEX Color Value:', testResult.observedHex ?? 'N/A'),
                        _buildTableRow(context, isAr ? 'قيمة اللون RGB:' : 'RGB Color Value:', testResult.observedRgb ?? 'N/A'),
                        _buildTableRow(context, isAr ? 'معدل الاختلاف Delta E:' : 'Delta E Difference:', testResult.deltaE?.toStringAsFixed(2) ?? 'N/A'),
                        _buildTableRow(context, isAr ? 'إصدار الخوارزمية:' : 'Algorithm Version:', testResult.algorithmVersion ?? '1.0.0'),
                        _buildTableRow(context, isAr ? 'إصدار قاعدة البيانات:' : 'Dataset Version:', ref.watch(dataSourceInfoProvider)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),
                ],
                if (rc.enableScientificReferences)
                  _AcademicReferencesCardSection(
                    reagentName: testResult.reagentName,
                    possibleSubstances: testResult.possibleSubstances,
                  ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1C1212)
                        : const Color(0xFFFDF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFFF87171).withValues(alpha: 0.2)
                          : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            HeroIcons.exclamation_triangle, 
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626), 
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'إخلاء مسؤولية علمي هام' : 'Important Scientific Disclaimer',
                            style: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFFF87171)
                                  : const Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Interpretations generated by this application are probabilistic analytical observations and not certified scientific conclusions. This application is intended solely for educational, analytical, and research-support workflows.',
                        style: AppTypography.getCaption(context).copyWith(height: 1.4),
                      ),
                      Divider(
                        color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                        height: 16,
                      ),
                      Text(
                        'النتائج المعروضة هي تفسيرات تحليلية احتمالية لأغراض تعليمية وبحثية فقط، ولا تمثل نتائج علمية أو مخبرية معتمدة.',
                        style: AppTypography.getCaption(context).copyWith(height: 1.4),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(240, 56),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      l10n.backToHome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(
    BuildContext context, {
    required double percentage,
    required String label,
    required Color accentColor,
  }) {
    final percentVal = percentage.clamp(0.0, 1.0);
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 56.0,
          lineWidth: 8.0,
          animation: true,
          percent: percentVal,
          center: Text(
            "${(percentVal * 100).toInt()}%",
            style: AppTypography.getCardTitle(context).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: accentColor,
          backgroundColor: accentColor.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.getCaption(context).copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: AppTypography.getCaption(context,
            color: theme.colorScheme.primary,
          ).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: AppTypography.getMetadataLabel(context,
              color: theme.colorScheme.onSurfaceVariant,
              isBold: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SelectableText(
            value,
            style: AppTypography.getMetadataValue(context).copyWith(
              fontFamily: 'Courier',
            ),
          ),
        ),
      ],
    );
  }

  Color _parseHexColor(String? hex, String colorName) {
    if (hex != null && hex.isNotEmpty) {
      try {
        final cleanHex = hex.replaceAll('#', '');
        return Color(int.parse('FF$cleanHex', radix: 16));
      } catch (_) {}
    }
    final lower = colorName.toLowerCase();
    if (lower.contains('purple') || lower.contains('violet') || lower.contains('بنفسجي')) {
      return const Color(0xFF8B5CF6);
    }
    if (lower.contains('orange') || lower.contains('برتقالي')) {
      return const Color(0xFFF97316);
    }
    if (lower.contains('brown') || lower.contains('بني')) {
      return const Color(0xFF92400E);
    }
    if (lower.contains('pink') || lower.contains('وردي')) {
      return const Color(0xFFEC4899);
    }
    return const Color(0xFF6B7280);
  }
}

class _SubstanceItem extends StatelessWidget {
  final String substance;
  const _SubstanceItem({required this.substance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(HeroIcons.beaker, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              substance,
              style: AppTypography.getMetadataValue(context).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademicReferencesCardSection extends ConsumerWidget {
  final String reagentName;
  final List<String> possibleSubstances;

  const _AcademicReferencesCardSection({
    required this.reagentName,
    required this.possibleSubstances,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    final jsonRefsAsync = ref.watch(reagentReferencesProvider(reagentName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(HeroIcons.book_open, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.references.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        jsonRefsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            isAr ? 'فشل تحميل المراجع' : 'Failed to load references',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          data: (refs) {
            final parsedRefs = refs.map((r) => ReferenceParser.parse(r)).toList();
            
            if (parsedRefs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      HeroIcons.information_circle, 
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.noReferencesAvailable,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: parsedRefs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final refData = parsedRefs[index];
                final apaString = refData.toAPAFormat();
                final citation = refData.toShortCitation();
                
                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.dividerColor,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                citation,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                HeroIcons.clipboard, 
                                size: 18, 
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.54),
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: apaString));
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isAr ? 'تم نسخ المرجع بنجاح!' : 'Reference copied successfully!'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: isAr ? 'نسخ المرجع' : 'Copy Reference',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          apaString,
                          style: AppTypography.getMetadataValue(context,
                            color: theme.colorScheme.onSurface,
                          ).copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

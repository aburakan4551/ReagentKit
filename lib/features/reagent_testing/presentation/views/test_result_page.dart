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

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          l10n.testResults,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LocalizationHelper.getBackChevronIcon(context), color: Colors.white),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          tooltip: l10n.backToHome,
        ),
        actions: [
          if (state is TestResultLoaded)
            IconButton(
              icon: const Icon(HeroIcons.share, color: Colors.white),
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
    if (state is TestResultLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C5CFF)),
        ),
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
              const Icon(HeroIcons.exclamation_circle, size: 64, color: Color(0xFFF87171)),
              const SizedBox(height: 16),
              Text(
                l10n.error(state.message),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CFF),
                  foregroundColor: Colors.white,
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
          style: const TextStyle(color: Colors.white70),
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

    final stabilityVal = testResult.stabilityIndex ?? 1.0;
    String stabilityText = isAr ? 'مستقر' : 'Stable Result';
    Color stabilityColor = const Color(0xFF34D399);
    if (stabilityVal < 0.6) {
      stabilityText = isAr ? 'غير مستقر' : 'Unstable Interpretation';
      stabilityColor = const Color(0xFFF87171);
    } else if (stabilityVal < 0.85) {
      stabilityText = isAr ? 'مستقر جزئياً' : 'Moderately Stable';
      stabilityColor = const Color(0xFFFBBF24);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF131722),
                  Color(0xFF0F1115),
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
                      accentColor: const Color(0xFF7C5CFF),
                    ),
                    _buildConfidenceIndicator(
                      context,
                      percentage: testResult.colorMatchConfidence ?? (testResult.confidencePercentage / 100.0),
                      label: isAr ? 'ثقة مطابقة اللون' : 'Color Match',
                      accentColor: const Color(0xFF5B8CFF),
                    ),
                  ],
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  isAr ? (testResult.reagentName == 'Marquis Test' ? 'اختبار ماركيز' : testResult.reagentName) : testResult.reagentName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.white,
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
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
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
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
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
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...testResult.possibleSubstances.map((substance) => _SubstanceItem(substance: substance)),
                      if (testResult.possibleSubstances.isEmpty)
                        Text(
                          l10n.unknownSubstance,
                          style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold),
                        ),
                      if (testResult.notes != null && testResult.notes!.isNotEmpty) ...[
                        const Divider(color: Colors.white10, height: 24),
                        Text(
                          isAr ? 'التفاصيل والتحليل:' : 'Analysis Details:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          testResult.notes!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            color: Colors.white,
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
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
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
                          color: _parseHexColor(testResult.observedHex, testResult.observedColor),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
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
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              testResult.observedColor,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF7C5CFF).withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
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
                        _buildTableRow(isAr ? 'قيمة اللون HEX:' : 'HEX Color Value:', testResult.observedHex ?? 'N/A'),
                        _buildTableRow(isAr ? 'قيمة اللون RGB:' : 'RGB Color Value:', testResult.observedRgb ?? 'N/A'),
                        _buildTableRow(isAr ? 'معدل الاختلاف Delta E:' : 'Delta E Difference:', testResult.deltaE?.toStringAsFixed(2) ?? 'N/A'),
                        _buildTableRow(isAr ? 'إصدار الخوارزمية:' : 'Algorithm Version:', testResult.algorithmVersion ?? '1.0.0'),
                        _buildTableRow(isAr ? 'إصدار قاعدة البيانات:' : 'Dataset Version:', ref.watch(dataSourceInfoProvider)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),
                ],
                _AcademicReferencesCardSection(
                  reagentName: testResult.reagentName,
                  possibleSubstances: testResult.possibleSubstances,
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1212),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF87171).withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(HeroIcons.exclamation_triangle, color: Color(0xFFF87171), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'إخلاء مسؤولية علمي هام' : 'Important Scientific Disclaimer',
                            style: const TextStyle(
                              color: Color(0xFFF87171),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Interpretations generated by this application are probabilistic analytical observations and not certified scientific conclusions. This application is intended solely for educational, analytical, and research-support workflows.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                      const Divider(color: Colors.white10, height: 16),
                      const Text(
                        'التفسيرات الناتجة عن هذا التطبيق هي ملاحظات تحليلية احتمالية وليست استنتاجات علمية معتمدة. هذا التطبيق مخصص فقط لسير العمل التعليمي والتحليلي ودعم الأبحاث.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
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
                      backgroundColor: const Color(0xFF7C5CFF),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      l10n.backToHome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
    final theme = Theme.of(context);
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: accentColor,
          backgroundColor: accentColor.withOpacity(0.1),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label, IconData icon) {
    const Color accent = Color(0xFF7C5CFF);
    return Row(
      children: [
        Icon(icon, size: 18, color: accent),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: accent,
            letterSpacing: 1.2,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SelectableText(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Courier'),
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
              color: const Color(0xFF7C5CFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(HeroIcons.beaker, size: 18, color: Color(0xFF7C5CFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              substance,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    final jsonRefsAsync = ref.watch(reagentReferencesProvider(reagentName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(HeroIcons.book_open, size: 18, color: Color(0xFF7C5CFF)),
            const SizedBox(width: 8),
            Text(
              l10n.references.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C5CFF),
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
            style: const TextStyle(color: Color(0xFFF87171)),
          ),
          data: (refs) {
            final parsedRefs = refs.map((r) => ReferenceParser.parse(r)).toList();
            
            if (parsedRefs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(HeroIcons.information_circle, color: Colors.white38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.noReferencesAvailable,
                        style: const TextStyle(color: Colors.white38),
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
                  color: const Color(0xFF161B22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.08)),
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
                                color: const Color(0xFF7C5CFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                citation,
                                style: const TextStyle(
                                  color: Color(0xFF7C5CFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(HeroIcons.clipboard, size: 18, color: Colors.white70),
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          apaString,
                          style: const TextStyle(
                            color: Colors.white,
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

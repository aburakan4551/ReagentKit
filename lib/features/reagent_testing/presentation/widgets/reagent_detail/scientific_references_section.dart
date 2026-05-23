import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:reagentkit/scientific_engine/reference_parser.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_typography.dart';

class ScientificReferencesSection extends StatelessWidget {
  final ReagentEntity reagent;

  const ScientificReferencesSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context) {
    final validReferences = reagent.references.where((r) => r.trim().isNotEmpty).toList();
    if (validReferences.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final parsedRefs = validReferences.map((r) => ReferenceParser.parse(r)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CFF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                HeroIcons.book_open,
                color: Color(0xFF7C5CFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.references,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
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
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF161B22)
                  : theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFE6E8F0),
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
                        IconButton(
                          icon: Icon(
                            HeroIcons.clipboard,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: apaString));
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAr
                                      ? 'تم نسخ المرجع بنجاح!'
                                      : 'Reference copied successfully!',
                                  style: TextStyle(color: theme.colorScheme.onSurface),
                                ),
                                backgroundColor: theme.brightness == Brightness.dark
                                    ? const Color(0xFF161B22)
                                    : theme.colorScheme.surfaceContainer,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
        ),
      ],
    );
  }
}


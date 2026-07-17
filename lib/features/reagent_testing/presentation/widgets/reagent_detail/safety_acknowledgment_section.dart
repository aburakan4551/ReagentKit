import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../controllers/reagent_detail_controller.dart';
import '../../../../../core/theme/app_typography.dart';

class SafetyAcknowledgmentSection extends ConsumerWidget {
  final ReagentEntity reagent;

  const SafetyAcknowledgmentSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isAcknowledged = ref.watch(reagentDetailControllerProvider);
    final controller = ref.read(reagentDetailControllerProvider.notifier);

    return Card(
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
            _buildSectionHeader(context, theme, l10n),
            const SizedBox(height: 16),
            _buildAcknowledgmentCheckbox(
              context,
              theme,
              l10n,
              isAcknowledged,
              controller,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            HeroIcons.shield_check,
            color: theme.colorScheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.safetyAcknowledgment,
            style: AppTypography.getSectionTitle(context).copyWith(
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcknowledgmentCheckbox(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    bool isAcknowledged,
    ReagentDetailController controller,
  ) {
    final textStyle = AppTypography.getMetadataValue(
      context,
      color: theme.colorScheme.onSurfaceVariant,
    ).copyWith(
      fontSize: 14,
      height: 1.4,
    );

    return InkWell(
      onTap: () => controller.setSafetyAcknowledgment(!isAcknowledged),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: isAcknowledged,
                  onChanged: (value) =>
                      controller.setSafetyAcknowledgment(value ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  activeColor: theme.colorScheme.primary,
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.safetyAcknowledgmentText,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

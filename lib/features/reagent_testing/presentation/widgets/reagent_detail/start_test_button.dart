import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:reagentkit/features/premium/presentation/screens/paywall_screen.dart';
import '../../providers/reagent_testing_providers.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../controllers/reagent_detail_controller.dart';

import '../../views/test_execution_page.dart';

class StartTestButton extends ConsumerWidget {
  final ReagentEntity reagent;

  const StartTestButton({super.key, required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAcknowledged = ref.watch(reagentDetailControllerProvider);
    final premiumService = ref.watch(premiumServiceProvider);

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isAcknowledged
                ? () {
                    if (premiumService.canAnalyze) {
                      _navigateToTest(context);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaywallScreen(),
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: isAcknowledged
                  ? theme.colorScheme.primary // Primary action color
                  : theme.colorScheme.onSurface.withOpacity(0.12), // Disabled color
              foregroundColor: isAcknowledged
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface.withOpacity(0.38),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAcknowledged
                      ? HeroIcons.play
                      : HeroIcons.exclamation_triangle,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  isAcknowledged
                      ? l10n.startTest
                      : l10n.safetyAcknowledgmentRequired,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestExecutionPage(reagent: reagent),
      ),
    );
  }
}

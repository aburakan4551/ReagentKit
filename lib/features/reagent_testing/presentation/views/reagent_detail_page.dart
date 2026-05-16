import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/reagent_entity.dart';
import '../../../../core/utils/localization_helper.dart';
import '../widgets/reagent_detail/reagent_header_card.dart';
import '../widgets/reagent_detail/safety_information_section.dart';
import '../widgets/reagent_detail/chemical_components_section.dart';
import '../widgets/reagent_detail/test_instructions_section.dart';
import '../widgets/reagent_detail/safety_acknowledgment_section.dart';
import '../widgets/reagent_detail/start_test_button.dart';

class ReagentDetailPage extends ConsumerWidget {
  final ReagentEntity reagent;

  const ReagentDetailPage({super.key, required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: const ReagentDetailBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(LocalizationHelper.getLocalizedReagentName(context, reagent)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(LocalizationHelper.getBackChevronIcon(context)),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: 'Back',
      ),
    );
  }
}

class ReagentDetailBody extends ConsumerWidget {
  const ReagentDetailBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reagent = _getReagentFromContext(context);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ReagentHeaderCard(reagent: reagent),
                    const SizedBox(height: 24),
                    SafetyInformationSection(reagent: reagent),
                    const SizedBox(height: 24),
                    ChemicalComponentsSection(reagent: reagent),
                    const SizedBox(height: 24),
                    TestInstructionsSection(reagent: reagent),
                    const SizedBox(height: 24),
                    SafetyAcknowledgmentSection(reagent: reagent),
                    const SizedBox(height: 24), // Space for bottom button
                  ]),
                ),
              ),
            ],
          ),
        ),
        StartTestButton(reagent: reagent),
      ],
    );
  }

  ReagentEntity _getReagentFromContext(BuildContext context) {
    // Get reagent from the nearest ReagentDetailPage widget
    return context.findAncestorWidgetOfExactType<ReagentDetailPage>()!.reagent;
  }
}

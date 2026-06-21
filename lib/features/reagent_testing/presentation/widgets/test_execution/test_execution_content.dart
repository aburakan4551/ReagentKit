import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reagentkit/features/reagent_testing/domain/entities/reagent_entity.dart';
import 'package:reagentkit/features/reagent_testing/presentation/widgets/test_execution/test_procedure_section.dart';
import 'package:reagentkit/features/reagent_testing/presentation/widgets/test_execution/reaction_timer_section.dart';
import 'package:reagentkit/features/reagent_testing/presentation/widgets/test_execution/ai_image_analysis_section.dart';
import 'package:reagentkit/features/reagent_testing/presentation/widgets/test_execution/observed_color_section.dart';
import 'package:reagentkit/features/reagent_testing/presentation/widgets/test_execution/test_notes_section.dart';
import 'package:reagentkit/features/reagent_testing/presentation/widgets/test_execution/complete_test_section.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';

class TestExecutionContent extends ConsumerWidget {
  final ReagentEntity reagent;

  const TestExecutionContent({super.key, required this.reagent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testExecutionState = ref.watch(testExecutionControllerProvider);
    final testExecutionController = ref.read(
      testExecutionControllerProvider.notifier,
    );

    // Get selected color from the current state
    final selectedColor = testExecutionState.maybeWhen(
      loaded: (execution, _, __) => execution.selectedColor,
      orElse: () => null,
    );

    final sections = [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: TestProcedureSection(reagent: reagent),
      ),
      const SizedBox(height: 16),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: ReactionTimerSection(),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: AIImageAnalysisSection(reagent: reagent),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ObservedColorSection(
          reagent: reagent,
          selectedColor: selectedColor,
          onColorSelected: (color) {
            testExecutionController.selectColor(color ?? '');
          },
        ),
      ),
      const SizedBox(height: 16),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: TestNotesSection(),
      ),
      const SizedBox(height: 24),
      CompleteTestSection(reagent: reagent),
      const SizedBox(height: 24),
    ];

    return CustomScrollView(
      // Add physics to improve scroll performance
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverList(
          // Use builder delegate to prevent unnecessary rebuilds during scrolling
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              // Only build visible items
              if (index >= sections.length) {
                return null;
              }
              return sections[index];
            },
            childCount: sections.length,
            // Disable semantic indexing for better performance
            semanticIndexCallback: (Widget widget, int localIndex) =>
                localIndex,
          ),
        ),
      ],
    );
  }
}

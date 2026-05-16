import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:reagentkit/l10n/app_localizations.dart';

class TestNotesSection extends ConsumerStatefulWidget {
  const TestNotesSection({super.key});

  @override
  ConsumerState<TestNotesSection> createState() => _TestNotesSectionState();
}

class _TestNotesSectionState extends ConsumerState<TestNotesSection> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final notes = ref
        .read(testExecutionControllerProvider)
        .maybeWhen(loaded: (execution, _, notes) => notes, orElse: () => null);
    if (notes != null) {
      _notesController.text = notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(testExecutionControllerProvider, (previous, next) {
      final notes = next.maybeWhen(
        loaded: (execution, _, notes) => notes,
        orElse: () => null,
      );
      if (notes != null && notes != _notesController.text) {
        _notesController.text = notes;
      }
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTestNotesTitle(l10n),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(_getTestNotesDescription(l10n)),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: _getTestNotesHint(l10n),
              ),
              onChanged: (value) {
                ref
                    .read(testExecutionControllerProvider.notifier)
                    .updateNotes(value);
              },
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  String _getTestNotesTitle(AppLocalizations l10n) {
    return l10n.localeName == 'ar' ? 'ملاحظات الاختبار' : 'Test Notes';
  }

  String _getTestNotesDescription(AppLocalizations l10n) {
    return l10n.localeName == 'ar'
        ? 'أضف أي ملاحظات حول الاختبار (مثل الفوران، الدخان).'
        : 'Add any notes about the test (e.g., fizzing, smoke).';
  }

  String _getTestNotesHint(AppLocalizations l10n) {
    return l10n.localeName == 'ar'
        ? 'أدخل الملاحظات هنا...'
        : 'Enter notes here...';
  }
}

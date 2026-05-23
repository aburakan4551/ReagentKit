import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:reagentkit/features/reagent_testing/data/models/reagent_test_model.dart';
import 'package:reagentkit/scientific_engine/reference_parser.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../../../core/theme/app_typography.dart';

// Provider to get all reagents from UnifiedDataService
final allReagentsProvider = FutureProvider<List<ReagentTestModel>>((ref) async {
  final dataService = ref.watch(unifiedDataServiceProvider);
  final snapshot = await dataService.getAllData();
  return snapshot.reagents;
});

class ScientificReferencesPage extends ConsumerStatefulWidget {
  const ScientificReferencesPage({super.key});

  @override
  ConsumerState<ScientificReferencesPage> createState() => _ScientificReferencesPageState();
}

class _ScientificReferencesPageState extends ConsumerState<ScientificReferencesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _sortByAlphabet = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reagentsAsync = ref.watch(allReagentsProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return reagentsAsync.when(
      loading: () => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            isAr ? 'المراجع العلمية' : 'Scientific References',
            style: AppTypography.getSectionTitle(context).copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              LocalizationHelper.getBackChevronIcon(context), 
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            isAr ? 'فشل تحميل قاعدة البيانات العلمية' : 'Failed to load scientific dataset',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              LocalizationHelper.getBackChevronIcon(context), 
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Text(
            isAr ? 'فشل تحميل قاعدة البيانات العلمية' : 'Failed to load scientific dataset',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ),
      data: (reagents) {
        // Filter reagents that have references
        var filteredList = reagents.where((r) => r.references.any((ref) => ref.trim().isNotEmpty)).toList();

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredList = filteredList.where((r) {
            final name = r.reagentName.toLowerCase();
            final nameAr = r.reagentNameAr.toLowerCase();
            final desc = r.description.toLowerCase();
            return name.contains(query) || nameAr.contains(query) || desc.contains(query);
          }).toList();
        }

        // Category filter
        final categories = {'All', ...reagents.map((r) => r.category).where((c) => c.isNotEmpty)};
        if (_selectedCategory != 'All') {
          filteredList = filteredList.where((r) => r.category == _selectedCategory).toList();
        }

        // Sort alphabetically
        if (_sortByAlphabet) {
          filteredList.sort((a, b) => a.reagentName.compareTo(b.reagentName));
        } else {
          filteredList.sort((a, b) => b.reagentName.compareTo(a.reagentName));
        }

        final totalReferencesCount = filteredList.fold<int>(
          0,
          (sum, r) => sum + r.references.where((ref) => ref.trim().isNotEmpty).length,
        );

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              isAr
                  ? 'المراجع العلمية ($totalReferencesCount)'
                  : 'Scientific References ($totalReferencesCount)',
              style: AppTypography.getSectionTitle(context).copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                LocalizationHelper.getBackChevronIcon(context), 
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _sortByAlphabet ? HeroIcons.bars_arrow_down : HeroIcons.bars_arrow_up,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () {
                  setState(() {
                    _sortByAlphabet = !_sortByAlphabet;
                  });
                  HapticFeedback.selectionClick();
                },
                tooltip: isAr ? 'ترتيب أبجدي' : 'Sort Alphabetically',
              ),
            ],
          ),
          body: Column(
            children: [
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Input
                    TextField(
                      controller: _searchController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: isAr ? 'ابحث عن كاشف علمي...' : 'Search reagents...',
                        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.38)),
                        prefixIcon: Icon(
                          HeroIcons.magnifying_glass, 
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  HeroIcons.x_mark, 
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        fillColor: theme.colorScheme.surface,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.dividerColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: theme.dividerColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Categories Chips
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                cat == 'All' ? (isAr ? 'الكل' : 'All') : cat,
                                style: TextStyle(
                                  color: isSelected 
                                      ? theme.colorScheme.onPrimary 
                                      : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                  HapticFeedback.selectionClick();
                                }
                              },
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected 
                                      ? Colors.transparent 
                                      : theme.dividerColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Reagents & References List
              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState(context, isAr)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final reagent = filteredList[index];
                          return _ReagentReferenceCard(reagent: reagent, isAr: isAr)
                              .animate()
                              .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                              .moveY(begin: 15, end: 0, curve: Curves.easeOut);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isAr) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                HeroIcons.book_open,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAr
                  ? 'لم يتم العثور على مراجع علمية متوافقة'
                  : 'No compatible scientific references found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'لا توجد مراجع تتطابق مع كاشف البحث المحدد حالياً في قاعدة البيانات.'
                  : 'No compatible scientific references found for this reagent dataset.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReagentReferenceCard extends StatelessWidget {
  final ReagentTestModel reagent;
  final bool isAr;

  const _ReagentReferenceCard({required this.reagent, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsedRefs = reagent.references
        .where((r) => r.trim().isNotEmpty)
        .map((r) => ReferenceParser.parse(r))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reagent Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(HeroIcons.beaker, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? reagent.reagentNameAr : reagent.reagentName,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reagent.category,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: theme.dividerColor,
            height: 1,
          ),
          // References List
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: parsedRefs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ref = parsedRefs[index];
                final apaString = ref.toAPAFormat();
                final citation = ref.toShortCitation();

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              citation,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              HeroIcons.clipboard, 
                              size: 16, 
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: apaString));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr ? 'تم نسخ المرجع بنجاح!' : 'Reference copied successfully!',
                                    style: TextStyle(color: theme.colorScheme.onSurface),
                                  ),
                                  backgroundColor: theme.colorScheme.surfaceContainer,
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
                      const SizedBox(height: 6),
                      Text(
                        apaString,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reagentkit/features/reagent_testing/presentation/providers/reagent_testing_providers.dart';
import 'package:reagentkit/features/reagent_testing/data/models/reagent_test_model.dart';
import 'package:reagentkit/scientific_engine/reference_parser.dart';
import '../../../../core/utils/localization_helper.dart';

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
    final reagentsAsync = ref.watch(allReagentsProvider);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text(
          isAr ? 'المراجع العلمية' : 'Scientific References',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F1115),
        elevation: 0,
        leading: IconButton(
          icon: Icon(LocalizationHelper.getBackChevronIcon(context), color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _sortByAlphabet ? HeroIcons.bars_arrow_down : HeroIcons.bars_arrow_up,
              color: Colors.white,
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
      body: reagentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C5CFF)),
          ),
        ),
        error: (err, _) => Center(
          child: Text(
            isAr ? 'فشل تحميل قاعدة البيانات العلمية' : 'Failed to load scientific dataset',
            style: const TextStyle(color: Color(0xFFF87171)),
          ),
        ),
        data: (reagents) {
          // Filter reagents that have references
          var filteredList = reagents.where((r) => r.references.isNotEmpty).toList();

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

          return Column(
            children: [
              // Search and Filter Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search Input
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: isAr ? 'ابحث عن كاشف علمي...' : 'Search reagents...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(HeroIcons.magnifying_glass, color: Colors.white38),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(HeroIcons.x_mark, color: Colors.white70),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        fillColor: const Color(0xFF161B22),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF7C5CFF)),
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
                                  color: isSelected ? Colors.white : Colors.white70,
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
                              selectedColor: const Color(0xFF7C5CFF),
                              backgroundColor: const Color(0xFF161B22),
                              side: BorderSide(
                                color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.08),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    ? _buildEmptyState(isAr)
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
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              child: const Icon(
                HeroIcons.book_open,
                size: 64,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isAr
                  ? 'لم يتم العثور على مراجع علمية متوافقة'
                  : 'No compatible scientific references found',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
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
              style: const TextStyle(
                color: Colors.white38,
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
    final parsedRefs = reagent.references.map((r) => ReferenceParser.parse(r)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    color: const Color(0xFF7C5CFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(HeroIcons.beaker, color: Color(0xFF7C5CFF), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? reagent.reagentNameAr : reagent.reagentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reagent.category,
                        style: const TextStyle(
                          color: Colors.white38,
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
          const Divider(color: Colors.white10, height: 1),
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
                    color: const Color(0xFF0F1115),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
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
                              color: const Color(0xFF7C5CFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              citation,
                              style: const TextStyle(
                                color: Color(0xFF7C5CFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(HeroIcons.clipboard, size: 16, color: Colors.white70),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: apaString));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isAr ? 'تم نسخ المرجع بنجاح!' : 'Reference copied successfully!',
                                  ),
                                  duration: const Duration(seconds: 2),
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
                        style: const TextStyle(
                          color: Colors.white70,
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

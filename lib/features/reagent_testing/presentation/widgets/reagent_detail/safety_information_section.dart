import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../domain/entities/reagent_entity.dart';
import '../../../../../l10n/app_localizations.dart';

enum SafetyIconType { equipment, procedures, hazards, storage }

class SafetyInformationSection extends StatelessWidget {
  final ReagentEntity reagent;

  const SafetyInformationSection({super.key, required this.reagent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, l10n),
        const SizedBox(height: 16),
        _SafetyDetailsCard(reagent: reagent),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            HeroIcons.exclamation_triangle, // Safety warning icon
            color: theme.colorScheme.error,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.safetyInformation,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SafetyDetailsCard extends StatelessWidget {
  final ReagentEntity reagent;

  const _SafetyDetailsCard({required this.reagent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final equipment = reagent.safetyEquipment.isNotEmpty 
        ? reagent.safetyEquipment 
        : (isArabic 
            ? const [
                "ضع نظارات أمان مقاومة للمواد الكيميائية",
                "قفازات مقاومة للمواد الكيميائية (نيتريل أو نيوبرين)",
                "معطف مختبر بأكمام طويلة",
                "أحذية مغلقة مقاومة للمواد الكيميائية",
                "جهاز تنفس عند الضرورة"
              ]
            : const [
                "Chemical-resistant safety goggles",
                "Chemical-resistant gloves (nitrile or neoprene)",
                "Lab coat with long sleeves",
                "Closed-toe chemical-resistant shoes",
                "Respirator when necessary"
              ]);

    final procedures = reagent.safetyProcedures.isNotEmpty
        ? reagent.safetyProcedures
        : (isArabic
            ? const [
                "العمل تحت غطاء الدخان إجباري",
                "ارتداء قفازات مقاومة للأحماض",
                "استخدام نظارات الأمان وواقي الوجه",
                "الاحتفاظ ببيكربونات الصوديوم للتحييد",
                "استخدام قطرات صغيرة فقط",
                "عدم خلط الكاشف مباشرة مع الماء"
              ]
            : const [
                "Work under fume hood mandatory",
                "Wear acid-resistant gloves",
                "Use safety goggles and face shield",
                "Keep sodium bicarbonate handy for neutralization",
                "Use only small drops",
                "Never mix reagent directly with water"
              ]);

    final hazards = reagent.safetyHazards.isNotEmpty
        ? reagent.safetyHazards
        : (isArabic
            ? const [
                "شديد التآكل - يحتوي على حمض الكبريتيك المركز",
                "يسبب حروق كيميائية شديدة",
                "أبخرة خطيرة - الفورمالديهايد",
                "تفاعل طارد للحرارة"
              ]
            : const [
                "Highly corrosive - contains concentrated sulfuric acid",
                "Causes severe chemical burns",
                "Dangerous fumes - formaldehyde",
                "Exothermic reaction"
              ]);

    final storage = reagent.safetyStorage.isNotEmpty
        ? reagent.safetyStorage
        : (isArabic
            ? const [
                "التخزين في مكان بارد وجاف",
                "بعيداً عن المواد القابلة للاشتعال",
                "في خزانة تخزين أحماض مخصصة",
                "وضع ملصق تحذيري واضح"
              ]
            : const [
                "Store in cool, dry place",
                "Away from flammable materials",
                "In dedicated acid storage cabinet",
                "Label with clear warning"
              ]);

    final safetyData = SafetyData(
      equipment: equipment,
      handlingProcedures: procedures,
      specificHazards: hazards,
      storage: storage,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _SafetyContent(safetyData: safetyData, l10n: l10n),
      ),
    );
  }
}

// ignore: unused_element
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

// ignore: unused_element
class _ErrorState extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;

  const _ErrorState({required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(HeroIcons.exclamation_triangle, color: theme.colorScheme.error),
        const SizedBox(height: 8),
        Text(
          l10n.errorLoadingSettings,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ],
    );
  }
}

class _SafetyContent extends StatelessWidget {
  final SafetyData safetyData;
  final AppLocalizations l10n;

  const _SafetyContent({required this.safetyData, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SafetySection(
          title: l10n.equipment,
          items: safetyData.equipment,
          iconType: SafetyIconType.equipment,
        ),
        const SizedBox(height: 16),
        _SafetySection(
          title: l10n.handlingProcedures,
          items: safetyData.handlingProcedures,
          iconType: SafetyIconType.procedures,
        ),
        const SizedBox(height: 16),
        _SafetySection(
          title: l10n.specificHazards,
          items: safetyData.specificHazards,
          iconType: SafetyIconType.hazards,
        ),
        const SizedBox(height: 16),
        _SafetySection(
          title: l10n.storage,
          items: safetyData.storage,
          iconType: SafetyIconType.storage,
        ),
      ],
    );
  }
}

class _SafetySection extends StatelessWidget {
  final String title;
  final List<String> items;
  final SafetyIconType iconType;

  const _SafetySection({
    required this.title,
    required this.items,
    required this.iconType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _getIconWidget(context, iconType),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _SafetyItem(item: item)),
      ],
    );
  }

  Widget _getIconWidget(BuildContext context, SafetyIconType iconType) {
    final color = Theme.of(context).colorScheme.primary;
    switch (iconType) {
      case SafetyIconType.equipment:
        return Icon(HeroIcons.shield_check, size: 24, color: color);
      case SafetyIconType.procedures:
        return Icon(
          HeroIcons.wrench_screwdriver,
          size: 24,
          color: color,
        );
      case SafetyIconType.hazards:
        return Icon(
          HeroIcons.exclamation_triangle,
          size: 24,
          color: Theme.of(context).colorScheme.error,
        );
      case SafetyIconType.storage:
        return Icon(HeroIcons.archive_box, size: 24, color: color);
    }
  }
}

class _SafetyItem extends StatelessWidget {
  final String item;

  const _SafetyItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class SafetyData {
  final List<String> equipment;
  final List<String> handlingProcedures;
  final List<String> specificHazards;
  final List<String> storage;

  const SafetyData({
    required this.equipment,
    required this.handlingProcedures,
    required this.specificHazards,
    required this.storage,
  });
}

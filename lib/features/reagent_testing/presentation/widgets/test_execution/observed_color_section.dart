import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:reagentkit/core/theme/reagent_color_palette.dart';
import 'package:reagentkit/features/reagent_testing/domain/entities/reagent_entity.dart';

class ColorOption {
  final String englishName;
  final String arabicName;
  final Color displayColor;

  const ColorOption({
    required this.englishName,
    required this.arabicName,
    required this.displayColor,
  });
}

class ObservedColorSection extends ConsumerStatefulWidget {
  final ReagentEntity reagent;
  final Function(String?) onColorSelected;
  final String? selectedColor;

  const ObservedColorSection({
    super.key,
    required this.reagent,
    required this.onColorSelected,
    this.selectedColor,
  });

  @override
  ConsumerState<ObservedColorSection> createState() =>
      _ObservedColorSectionState();
}

class _ObservedColorSectionState extends ConsumerState<ObservedColorSection> {
  bool _isExpanded = false;

  // Get colors specific to the current reagent
  List<ColorOption> get _reagentColorOptions {
    final colorOptions = <ColorOption>[];
    final seenColors = <String>{};

    for (final drugResult in widget.reagent.drugResults) {
      // Only add unique colors (avoid duplicates)
      if (!seenColors.contains(drugResult.color)) {
        seenColors.add(drugResult.color);
        colorOptions.add(
          ColorOption(
            englishName: drugResult.color,
            arabicName: drugResult.colorAr,
            displayColor: _getDisplayColorForName(drugResult.color),
          ),
        );
      }
    }

    return colorOptions;
  }

  // Map color names to appropriate display colors using central palette
  Color _getDisplayColorForName(String colorName) {
    return ReagentColorPalette.getDisplayColor(colorName);
  }

  bool _isRtl(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  String _getColorName(ColorOption colorOption, BuildContext context) {
    return _isRtl(context) ? colorOption.arabicName : colorOption.englishName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
        color: theme.colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      HeroIcons.swatch,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isRtl(context)
                              ? 'اللون المُلاحظ'
                              : 'Observed Color',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRtl(context)
                              ? 'اختر اللون الذي لاحظته أثناء التفاعل'
                              : 'Select the color you observed during the reaction',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      _isExpanded
                          ? HeroIcons.chevron_up
                          : HeroIcons.chevron_down,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRtl(context)
                            ? 'خيارات الألوان المتاحة:'
                            : 'Available Color Options:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              childAspectRatio: 4.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _reagentColorOptions.length,
                        itemBuilder: (context, index) {
                          final colorOption = _reagentColorOptions[index];
                          final colorName = _getColorName(
                            colorOption,
                            context,
                          );
                          final isSelected =
                              widget.selectedColor == colorOption.englishName;

                          return GestureDetector(
                            onTap: () {
                              widget.onColorSelected(colorOption.englishName);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: colorOption.displayColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.colorScheme.outline,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        colorName,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: isSelected
                                              ? theme.colorScheme.onSurface
                                              : theme.colorScheme.onSurfaceVariant,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: _isRtl(context)
                                            ? TextAlign.right
                                            : TextAlign.left,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          HeroIcons.check,
                                          color: theme.colorScheme.onPrimary,
                                          size: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              if (widget.selectedColor != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        HeroIcons.check_circle,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isRtl(context)
                              ? 'اللون المُلاحظ: ${_getSelectedColorName()}'
                              : 'Observed Color: ${_getSelectedColorName()}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getSelectedColorName() {
    if (widget.selectedColor == null) return '';

    final selectedOption = _reagentColorOptions.firstWhere(
      (option) => option.englishName == widget.selectedColor,
      orElse: () => const ColorOption(
        englishName: '',
        arabicName: '',
        displayColor: Colors.grey,
      ),
    );

    return _getColorName(selectedOption, context);
  }
}

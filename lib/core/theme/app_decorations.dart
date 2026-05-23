import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class AppDecorations {
  static BoxDecoration get glassSurface => BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: AppDimensions.roundedLarge,
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      );

  static BoxDecoration get elevatedSurface => BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppDimensions.roundedMedium,
        border: Border.all(
          color: AppColors.borderHighlight,
          width: 1,
        ),
      );

  static BoxDecoration get bottomNavSurface => BoxDecoration(
        color: AppColors.overlayDark,
        borderRadius: AppDimensions.roundedXLarge,
        border: Border.all(
          color: AppColors.borderSubtle.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      );
}

import 'package:flutter/material.dart';

class LayoutHelper {
  LayoutHelper._();

  /// Calculates the exact bottom padding required for scroll views or lists
  /// to ensure content is fully scrollable and not hidden behind the floating bottom nav bar.
  static double getBottomNavPadding(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const double navBarHeight = 72.0;
    final double bottomMargin = bottomInset > 0 ? bottomInset : 24.0;
    const double breathingRoom = 16.0;
    
    return navBarHeight + bottomMargin + breathingRoom;
  }
  
  /// Helper to get a dynamic bottom padding EdgeInsets
  static EdgeInsets getBottomPaddingEdgeInsets(BuildContext context) {
    return EdgeInsets.only(bottom: getBottomNavPadding(context));
  }
}

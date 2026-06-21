import 'dart:math';

class RGBColor {
  final int r;
  final int g;
  final int b;

  const RGBColor(this.r, this.g, this.b);

  factory RGBColor.fromHex(String hex) {
    var hexStr = hex.replaceAll('#', '').trim();
    if (hexStr.length == 3) {
      hexStr = hexStr.split('').map((c) => c + c).join();
    }
    if (hexStr.length != 6) {
      return const RGBColor(0, 0, 0);
    }
    final val = int.tryParse(hexStr, radix: 16);
    if (val == null) {
      return const RGBColor(0, 0, 0);
    }
    return RGBColor(
      (val >> 16) & 0xFF,
      (val >> 8) & 0xFF,
      val & 0xFF,
    );
  }

  String toHex() {
    String pad(int value) => value.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${pad(r)}${pad(g)}${pad(b)}';
  }

  @override
  String toString() => 'RGB($r, $g, $b)';
}

class LabColor {
  final double L;
  final double a;
  final double b;

  const LabColor(this.L, this.a, this.b);
}

class ColorMatcher {
  // Map common scientific reagent colors to their RGB values
  static const Map<String, List<RGBColor>> _colorDictionary = {
    'purple': [RGBColor(128, 0, 128), RGBColor(106, 13, 173)],
    'violet': [RGBColor(148, 0, 211), RGBColor(138, 43, 226)],
    'brown': [RGBColor(139, 69, 19), RGBColor(160, 82, 45), RGBColor(165, 42, 42)],
    'orange': [RGBColor(255, 140, 0), RGBColor(255, 165, 0)],
    'pink': [RGBColor(255, 192, 203), RGBColor(255, 105, 180)],
    'blue': [RGBColor(0, 0, 255), RGBColor(0, 0, 139), RGBColor(70, 130, 180)],
    'green': [RGBColor(0, 128, 0), RGBColor(34, 139, 34), RGBColor(0, 100, 0)],
    'red': [RGBColor(255, 0, 0), RGBColor(178, 34, 34), RGBColor(139, 0, 0)],
    'yellow': [RGBColor(255, 255, 0), RGBColor(255, 215, 0)],
    'black': [RGBColor(0, 0, 0), RGBColor(15, 15, 15)],
    'white': [RGBColor(255, 255, 255)],
    'grey': [RGBColor(128, 128, 128)],
    'gray': [RGBColor(128, 128, 128)],
    'rose': [RGBColor(255, 0, 127)],
    'brownish': [RGBColor(139, 69, 19)],
    'yellowish': [RGBColor(255, 255, 102)],
  };

  /// Parses a textual color description (e.g. "purple to violet" or "red-brown")
  /// into a list of representative RGBColors.
  static List<RGBColor> parseColorDescription(String description) {
    final cleanDesc = description.toLowerCase().replaceAll('-', ' ').replaceAll(',', ' ');
    final matchedColors = <RGBColor>[];

    _colorDictionary.forEach((key, rgbList) {
      if (cleanDesc.contains(key)) {
        matchedColors.addAll(rgbList);
      }
    });

    // Fallback if no color matches description text
    if (matchedColors.isEmpty) {
      matchedColors.add(const RGBColor(128, 128, 128)); // Neutral grey
    }

    return matchedColors;
  }

  /// Converts RGB color to XYZ color space (Helper)
  static LabColor rgbToLab(RGBColor color) {
    // Normalise RGB to [0, 1]
    double r = color.r / 255.0;
    double g = color.g / 255.0;
    double b = color.b / 255.0;

    // Gamma correction
    r = (r > 0.04045) ? pow((r + 0.055) / 1.055, 2.4).toDouble() : r / 12.92;
    g = (g > 0.04045) ? pow((g + 0.055) / 1.055, 2.4).toDouble() : g / 12.92;
    b = (b > 0.04045) ? pow((b + 0.055) / 1.055, 2.4).toDouble() : b / 12.92;

    // Convert to XYZ using D65 sRGB matrix
    double x = (r * 0.4124 + g * 0.3576 + b * 0.1805) * 100.0;
    double y = (r * 0.2126 + g * 0.7152 + b * 0.0722) * 100.0;
    double z = (r * 0.0193 + g * 0.1192 + b * 0.9505) * 100.0;

    // Convert XYZ to CIELAB
    // Reference white point: D65 (Xn=95.047, Yn=100.000, Zn=108.883)
    double xr = x / 95.047;
    double yr = y / 100.000;
    double zr = z / 108.883;

    double f(double t) {
      return (t > 0.008856) ? pow(t, 1.0 / 3.0).toDouble() : (7.787 * t) + (16.0 / 116.0);
    }

    double fx = f(xr);
    double fy = f(yr);
    double fz = f(zr);

    double lVal = (116.0 * fy) - 16.0;
    double aVal = 500.0 * (fx - fy);
    double bVal = 200.0 * (fy - fz);

    return LabColor(lVal, aVal, bVal);
  }

  /// Calculates the CIE76 color difference (Delta E) between two RGB colors
  static double calculateDeltaE(RGBColor c1, RGBColor c2) {
    final lab1 = rgbToLab(c1);
    final lab2 = rgbToLab(c2);

    final dL = lab1.L - lab2.L;
    final da = lab1.a - lab2.a;
    final db = lab1.b - lab2.b;

    return sqrt(dL * dL + da * da + db * db);
  }

  /// Finds the closest match between a test color and target description
  static double getMinDeltaE(RGBColor testColor, String targetDescription) {
    final targets = parseColorDescription(targetDescription);
    double minDelta = double.infinity;

    for (final target in targets) {
      final delta = calculateDeltaE(testColor, target);
      if (delta < minDelta) {
        minDelta = delta;
      }
    }

    return minDelta;
  }
}

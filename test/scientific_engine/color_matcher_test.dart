import 'package:flutter_test/flutter_test.dart';
import 'package:reagentkit/scientific_engine/color_matcher.dart';

void main() {
  group('RGBColor Tests', () {
    test('Constructor creates RGBColor', () {
      const color = RGBColor(10, 20, 30);
      expect(color.r, 10);
      expect(color.g, 20);
      expect(color.b, 30);
    });

    test('fromHex parses 6-digit hex with hash', () {
      final color = RGBColor.fromHex('#FF8C00'); // Orange
      expect(color.r, 255);
      expect(color.g, 140);
      expect(color.b, 0);
    });

    test('fromHex parses 6-digit hex without hash', () {
      final color = RGBColor.fromHex('0000FF'); // Blue
      expect(color.r, 0);
      expect(color.g, 0);
      expect(color.b, 255);
    });

    test('fromHex parses 3-digit hex with hash', () {
      final color = RGBColor.fromHex('#F00'); // Red (#FF0000)
      expect(color.r, 255);
      expect(color.g, 0);
      expect(color.b, 0);
    });

    test('fromHex handles invalid hex strings gracefully', () {
      final color = RGBColor.fromHex('#XYZ');
      expect(color.r, 0);
      expect(color.g, 0);
      expect(color.b, 0);
    });

    test('toHex formats correct string representation', () {
      const color = RGBColor(128, 0, 128); // Purple
      expect(color.toHex(), '#800080');
    });

    test('toString formats correctly', () {
      const color = RGBColor(255, 255, 255);
      expect(color.toString(), 'RGB(255, 255, 255)');
    });
  });

  group('ColorMatcher Parsing Tests', () {
    test('parseColorDescription extracts valid colors from string', () {
      final colors = ColorMatcher.parseColorDescription('red-brown to violet');
      // Should find red, brown, and violet
      expect(colors, isNotEmpty);

      final hexList = colors.map((c) => c.toHex()).toList();
      // Red: #FF0000, #B22222, #8B0000
      // Brown: #8B4513, #A0522D, #A52A2A
      // Violet: #9400D3, #8A2BE2
      expect(hexList, contains('#FF0000'));
      expect(hexList, contains('#8B4513'));
      expect(hexList, contains('#9400D3'));
    });

    test('parseColorDescription fallbacks to grey for unknown text', () {
      final colors =
          ColorMatcher.parseColorDescription('completely unknown pattern');
      expect(colors.length, 1);
      expect(colors.first.toHex(), '#808080'); // Neutral grey
    });
  });

  group('Color Space Conversion & Delta E Tests', () {
    test('rgbToLab converts pure colors correctly', () {
      const black = RGBColor(0, 0, 0);
      const white = RGBColor(255, 255, 255);

      final labBlack = ColorMatcher.rgbToLab(black);
      final labWhite = ColorMatcher.rgbToLab(white);

      // Black L value should be close to 0
      expect(labBlack.L, closeTo(0.0, 0.5));
      // White L value should be close to 100
      expect(labWhite.L, closeTo(100.0, 0.5));
    });

    test('calculateDeltaE returns 0.0 for identical colors', () {
      const color = RGBColor(100, 150, 200);
      final deltaE = ColorMatcher.calculateDeltaE(color, color);
      expect(deltaE, 0.0);
    });

    test('calculateDeltaE matches deltaE between red and green as substantial',
        () {
      const red = RGBColor(255, 0, 0);
      const green = RGBColor(0, 255, 0);
      final deltaE = ColorMatcher.calculateDeltaE(red, green);
      // CIE76 Delta E for red vs green is very large (> 80)
      expect(deltaE, greaterThan(80.0));
    });

    test('getMinDeltaE finds closest distance to target colors in description',
        () {
      const observed = RGBColor(255, 10, 10); // Very close to red
      // Target matches "red" which contains RGB(255,0,0)
      final minDelta = ColorMatcher.getMinDeltaE(observed, 'red-brown');
      expect(minDelta, lessThan(10.0));
    });
  });
}

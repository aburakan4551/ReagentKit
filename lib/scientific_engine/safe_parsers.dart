import 'dart:developer' as developer;
import 'color_matcher.dart';

/// Top-level safeEnum helper as requested by user.
T? safeEnum<T>(List<T> values, dynamic raw) {
  if (raw == null) return null;
  final value = raw.toString().trim().toLowerCase();
  for (final item in values) {
    if (item.toString().split('.').last.toLowerCase() == value) {
      return item;
    }
  }
  return null;
}

/// Resilient JSON type coercion helper methods.
class SafeJsonParser {
  static T? safeEnum<T>(List<T> values, dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim().toLowerCase();
    for (final item in values) {
      if (item.toString().split('.').last.toLowerCase() == value) {
        return item;
      }
    }
    return null;
  }

  static String safeString(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    return v.toString();
  }

  static int safeInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    if (v is String) {
      return int.tryParse(v) ?? fallback;
    }
    return fallback;
  }

  static double safeDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v) ?? fallback;
    }
    return fallback;
  }

  static List<T> safeList<T>(dynamic v, [List<T> fallback = const []]) {
    if (v == null) return fallback;
    if (v is! List) {
      developer.log(
        'SafeJsonParser: expected list but got ${v.runtimeType}, wrapping/returning fallback',
        name: 'ScientificParser',
      );
      try {
        if (v is T) return [v];
      } catch (_) {}
      return fallback;
    }
    try {
      return v.cast<T>().toList();
    } catch (_) {
      try {
        // Fallback manually map elements to handle type conversions
        return v.map((item) {
          if (T == String) {
            return item?.toString() as T;
          } else if (T == int) {
            return safeInt(item) as T;
          } else if (T == double) {
            return safeDouble(item) as T;
          }
          return item as T;
        }).toList();
      } catch (e) {
        developer.log(
          'SafeJsonParser: safeList conversion failed for $v',
          error: e,
          name: 'ScientificParser',
        );
        return fallback;
      }
    }
  }

  static Map<String, dynamic> safeMap(dynamic v,
      [Map<String, dynamic> fallback = const {}]) {
    if (v == null || v is! Map) return fallback;
    try {
      return Map<String, dynamic>.from(v);
    } catch (e) {
      developer.log(
        'SafeJsonParser: safeMap conversion failed for $v',
        error: e,
        name: 'ScientificParser',
      );
      return fallback;
    }
  }
}

/// Resilient color parsing helper methods.
class SafeColorParser {
  /// Safely parse color hex or text into a hex string or RGBColor.
  /// Falls back to neutral grey if invalid.
  static RGBColor safeColor(dynamic v,
      [RGBColor fallback = const RGBColor(128, 128, 128)]) {
    if (v == null) return fallback;
    return parseRobustColor(v.toString(), fallback);
  }

  static String safeColorHex(dynamic v, [String fallback = '#808080']) {
    if (v == null) return fallback;
    final parsed = parseRobustColor(v.toString(), RGBColor.fromHex(fallback));
    return parsed.toHex();
  }

  static RGBColor parseRobustColor(String input,
      [RGBColor fallback = const RGBColor(128, 128, 128)]) {
    var str = input.trim();
    if (str.isEmpty) return fallback;

    // Handle rgb(r, g, b) or rgb(r,g,b)
    if (str.toLowerCase().startsWith('rgb')) {
      try {
        final regExp = RegExp(r'rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)');
        final match = regExp.firstMatch(str);
        if (match != null) {
          final r = int.parse(match.group(1)!);
          final g = int.parse(match.group(2)!);
          final b = int.parse(match.group(3)!);
          return RGBColor(r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
        }
      } catch (e) {
        developer.log(
          'Failed to parse rgb color: $str',
          error: e,
          name: 'SafeColorParser',
        );
      }
    }

    // Check hex prefixes/patterns
    var hex = str;
    if (hex.startsWith('0x') || hex.startsWith('0X')) {
      hex = hex.substring(2);
    } else if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }

    // Clean non-hex characters
    hex = hex.replaceAll(RegExp(r'[^a-fA-F0-9]'), '');

    if (hex.length == 8) {
      // ARGB format: e.g. FFFF0000 -> alpha is first 2 chars, RGB is last 6
      hex = hex.substring(2);
    }

    if (hex.length == 6) {
      try {
        final val = int.tryParse(hex, radix: 16);
        if (val != null) {
          return RGBColor(
            (val >> 16) & 0xFF,
            (val >> 8) & 0xFF,
            val & 0xFF,
          );
        }
      } catch (_) {}
    } else if (hex.length == 3) {
      try {
        final expanded = hex.split('').map((c) => c + c).join();
        final val = int.tryParse(expanded, radix: 16);
        if (val != null) {
          return RGBColor(
            (val >> 16) & 0xFF,
            (val >> 8) & 0xFF,
            val & 0xFF,
          );
        }
      } catch (_) {}
    }

    // Check color description dictionary as fallback
    final matched = ColorMatcher.parseColorDescription(input);
    if (matched.isNotEmpty) {
      return matched.first;
    }

    return fallback;
  }
}

/// Resilient reference parsing helper methods.
class SafeReferenceParser {
  /// Cleans and formats reference strings.
  static String safeReference(dynamic v,
      [String fallback = 'Unknown Reference']) {
    if (v == null) return fallback;
    final raw = v.toString().trim();
    if (raw.isEmpty) return fallback;
    return raw;
  }
}

/// Resilient reaction data parsing helper methods.
class SafeReactionParser {
  /// Safely extracts the substance/analyte name, supporting both legacy 'drugName'
  /// and compliance-safe 'analyteName' keys.
  static String safeAnalyteName(Map<String, dynamic> json,
      [String fallback = 'Unknown Analyte']) {
    final name = json['analyteName'] ??
        json['drugName'] ??
        json['substance'] ??
        json['name'];
    return SafeJsonParser.safeString(name, fallback);
  }
}

import 'package:flutter/material.dart';

/// A self-contained, performant AutoSizeText widget that dynamically shrinks text
/// font size to fit within constraints and avoid text overflow or layout clipping.
class AutoSizeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final double minFontSize;
  final double maxFontSize;
  final double stepGranularity;
  final TextOverflow overflow;
  final TextAlign textAlign;

  const AutoSizeText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.minFontSize = 12,
    this.maxFontSize = 32,
    this.stepGranularity = 0.5,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultStyle =
        style ?? theme.textTheme.bodyMedium ?? const TextStyle();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxHeight = constraints.maxHeight.isInfinite
            ? double.infinity
            : constraints.maxHeight;

        double fontSize = defaultStyle.fontSize ?? 14.0;
        if (fontSize > maxFontSize) {
          fontSize = maxFontSize;
        }

        // We step down the font size until the text fits within constraints
        while (fontSize > minFontSize) {
          final testStyle = defaultStyle.copyWith(fontSize: fontSize);
          final textPainter = TextPainter(
            text: TextSpan(text: text, style: testStyle),
            textDirection: Directionality.of(context),
            maxLines: maxLines,
          );

          textPainter.layout(maxWidth: maxWidth);

          // Check if any individual word exceeds the maxWidth at this fontSize
          bool anyWordExceedsWidth = false;
          final words = text.split(RegExp(r'\s+'));
          for (final word in words) {
            if (word.trim().isEmpty) continue;
            final wordPainter = TextPainter(
              text: TextSpan(text: word, style: testStyle),
              textDirection: Directionality.of(context),
            );
            wordPainter.layout();
            if (wordPainter.width > maxWidth) {
              anyWordExceedsWidth = true;
              break;
            }
          }

          // If the text exceeds allowed lines, overflows height, or any individual word exceeds constraints, reduce font size
          if (textPainter.didExceedMaxLines ||
              (maxHeight != double.infinity &&
                  textPainter.height > maxHeight) ||
              anyWordExceedsWidth) {
            fontSize -= stepGranularity;
          } else {
            break;
          }
        }

        // Enforce minFontSize boundary
        if (fontSize < minFontSize) {
          fontSize = minFontSize;
        }

        return Text(
          text,
          style: defaultStyle.copyWith(fontSize: fontSize),
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}

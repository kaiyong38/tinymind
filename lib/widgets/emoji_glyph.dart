import 'package:flutter/material.dart';

class EmojiGlyph extends StatelessWidget {
  const EmojiGlyph(this.emoji, this.size, {super.key});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          emoji,
          maxLines: 1,
          softWrap: false,
          textAlign: TextAlign.center,
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: TextStyle(
            inherit: false,
            fontSize: size,
            height: 1,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}

class EmojiText extends StatelessWidget {
  const EmojiText(
    this.text, {
    required this.style,
    this.textAlign,
    this.maxLines,
    this.softWrap = true,
    super.key,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool softWrap;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final runes = text.runes.toList(growable: false);
    final plain = StringBuffer();

    void flushPlain() {
      if (plain.isNotEmpty) {
        spans.add(TextSpan(text: plain.toString()));
        plain.clear();
      }
    }

    for (var index = 0; index < runes.length;) {
      if (!_isEmojiBase(runes[index])) {
        plain.writeCharCode(runes[index]);
        index++;
        continue;
      }

      flushPlain();
      final cluster = StringBuffer()..writeCharCode(runes[index]);
      index++;
      if (index < runes.length && _isRegionalIndicator(runes[index])) {
        cluster.writeCharCode(runes[index++]);
      }
      while (index < runes.length) {
        final rune = runes[index];
        if (_isEmojiModifier(rune) || _isVariationSelector(rune) ||
            _isEmojiTag(rune) || rune == 0x20E3) {
          cluster.writeCharCode(rune);
          index++;
          continue;
        }
        if (rune == 0x200D && index + 1 < runes.length) {
          cluster
            ..writeCharCode(rune)
            ..writeCharCode(runes[index + 1]);
          index += 2;
          continue;
        }
        break;
      }

      final fontSize = style.fontSize ?? 14;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: EmojiGlyph(cluster.toString(), fontSize),
        ),
      );
    }
    flushPlain();

    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }

  static bool _isEmojiBase(int rune) =>
      (rune >= 0x1F000 && rune <= 0x1FAFF) ||
      (rune >= 0x2600 && rune <= 0x27FF) ||
      (rune >= 0x2300 && rune <= 0x23FF) ||
      (rune >= 0x1F1E6 && rune <= 0x1F1FF) ||
      rune == 0x00A9 ||
      rune == 0x00AE ||
      rune == 0x203C ||
      rune == 0x2049 ||
      rune == 0x2122 ||
      rune == 0x2139 ||
      rune == 0x3030 ||
      rune == 0x303D ||
      rune == 0x3297 ||
      rune == 0x3299;

  static bool _isRegionalIndicator(int rune) =>
      rune >= 0x1F1E6 && rune <= 0x1F1FF;

  static bool _isEmojiModifier(int rune) =>
      rune >= 0x1F3FB && rune <= 0x1F3FF;

  static bool _isVariationSelector(int rune) =>
      (rune >= 0xFE00 && rune <= 0xFE0F) ||
      (rune >= 0xE0100 && rune <= 0xE01EF);

  static bool _isEmojiTag(int rune) => rune >= 0xE0020 && rune <= 0xE007F;
}

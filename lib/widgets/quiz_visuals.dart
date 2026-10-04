import 'package:flutter/material.dart';

import '../models/learning.dart';
import '../services/accessibility_settings.dart';
import 'emoji_glyph.dart';

/// Renders the visual for a [QuizOption] according to [visual] — a colour
/// swatch, a drawn shape, a big letter over its picture, or a repeated
/// counting emoji — shared by the drag-answer tiles and the teach card.
Widget buildQuizVisual(
    BuildContext context, QuizOption option, AnswerVisual visual,
    {double size = 40}) {
  final fallbackColor = option.color ?? Colors.grey;

  switch (visual) {
    case AnswerVisual.picture:
      return SizedBox.square(
        dimension: size,
        child: Center(
          child: option.emoji == null
              ? const SizedBox.shrink()
              : EmojiGlyph(option.emoji!, size * 0.6),
        ),
      );
    case AnswerVisual.colorSwatch:
      final colorFriendlyMode =
          AccessibilitySettingsScope.of(context).colorFriendlyMode;
      final labelFontSize = (size * 0.24).clamp(14.0, 24.0);
      final swatchSize = colorFriendlyMode
          ? (size * 0.68).clamp(40.0, size - 17).toDouble()
          : size;
      final swatch = Container(
        width: swatchSize,
        height: swatchSize,
        decoration: BoxDecoration(
          color: fallbackColor,
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.black.withValues(alpha: 0.08), width: 2),
        ),
        child: colorFriendlyMode
            ? ClipOval(
                child: CustomPaint(
                  size: Size.square(swatchSize),
                  painter: ColorPatternPainter(option.label, fallbackColor),
                ),
              )
            : null,
      );
      if (!colorFriendlyMode) return swatch;
      return SizedBox.square(
        dimension: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch,
            const SizedBox(height: 3),
            Flexible(
              fit: FlexFit.loose,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  option.label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    case AnswerVisual.shape:
      return ShapeGlyph(
        kind: option.label,
        color: fallbackColor,
        size: size,
      );
    case AnswerVisual.letterPicture:
      return SizedBox.square(
        dimension: size,
        child: option.emoji == null
            ? Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: size * 0.48,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    flex: 6,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        option.label,
                        style: TextStyle(
                          fontSize: size * 0.48,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 4,
                    child: Center(
                      child: EmojiGlyph(option.emoji!, size * 0.36),
                    ),
                  ),
                ],
              ),
      );
    case AnswerVisual.numberDots:
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: List.generate(
          option.count ?? 0,
          (_) => option.emoji == null
              ? Text('•', style: TextStyle(fontSize: size * 0.42))
              : EmojiGlyph(option.emoji!, size * 0.42),
        ),
      );
    case AnswerVisual.text:
      return Text(option.label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w900));
  }
}

enum _ColorPattern {
  vertical,
  horizontal,
  diagonal,
  dots,
  grid,
  waves,
  cross,
  triangles,
}

_ColorPattern _patternForLabel(String label) {
  switch (label.trim().toLowerCase()) {
    case 'red':
      return _ColorPattern.vertical;
    case 'blue':
      return _ColorPattern.horizontal;
    case 'yellow':
      return _ColorPattern.diagonal;
    case 'green':
      return _ColorPattern.dots;
    case 'orange':
      return _ColorPattern.grid;
    case 'purple':
      return _ColorPattern.waves;
    case 'pink':
      return _ColorPattern.cross;
    case 'brown':
      return _ColorPattern.triangles;
    default:
      return _ColorPattern.diagonal;
  }
}

class ColorPatternPainter extends CustomPainter {
  ColorPatternPainter(this.label, this.color);

  final String label;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.save();
    canvas.clipPath(Path()..addOval(bounds));

    final luminance = color.computeLuminance();
    final paint = Paint()
      ..color = (luminance < 0.35 ? Colors.white : Colors.black)
          .withValues(alpha: 0.35)
      ..strokeWidth = (size.shortestSide * 0.07).clamp(1.5, 4).toDouble()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final spacing = size.shortestSide / 4;

    switch (_patternForLabel(label)) {
      case _ColorPattern.vertical:
        for (var x = spacing / 2; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
      case _ColorPattern.horizontal:
        for (var y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case _ColorPattern.diagonal:
        for (var offset = -size.height;
            offset < size.width;
            offset += spacing) {
          canvas.drawLine(
            Offset(offset, 0),
            Offset(offset + size.height, size.height),
            paint,
          );
        }
      case _ColorPattern.dots:
        final dotPaint = Paint()
          ..color = paint.color
          ..style = PaintingStyle.fill;
        for (var x = spacing / 2; x < size.width; x += spacing) {
          for (var y = spacing / 2; y < size.height; y += spacing) {
            canvas.drawCircle(Offset(x, y), paint.strokeWidth * 0.8, dotPaint);
          }
        }
      case _ColorPattern.grid:
        for (var x = spacing / 2; x < size.width; x += spacing) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        for (var y = spacing / 2; y < size.height; y += spacing) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
        }
      case _ColorPattern.waves:
        for (var y = spacing / 2; y < size.height; y += spacing) {
          final path = Path()..moveTo(0, y);
          for (var x = 0.0; x < size.width; x += spacing) {
            path.quadraticBezierTo(
              x + spacing / 4,
              y - spacing / 3,
              x + spacing / 2,
              y,
            );
            path.quadraticBezierTo(
              x + spacing * 3 / 4,
              y + spacing / 3,
              x + spacing,
              y,
            );
          }
          canvas.drawPath(path, paint);
        }
      case _ColorPattern.cross:
        for (var x = spacing / 2; x < size.width; x += spacing) {
          for (var y = spacing / 2; y < size.height; y += spacing) {
            canvas.drawLine(
                Offset(x - spacing / 3, y), Offset(x + spacing / 3, y), paint);
            canvas.drawLine(
                Offset(x, y - spacing / 3), Offset(x, y + spacing / 3), paint);
          }
        }
      case _ColorPattern.triangles:
        for (var x = spacing / 2; x < size.width; x += spacing) {
          for (var y = spacing / 2; y < size.height; y += spacing) {
            final path = Path()
              ..moveTo(x, y - spacing / 3)
              ..lineTo(x + spacing / 3, y + spacing / 3)
              ..lineTo(x - spacing / 3, y + spacing / 3)
              ..close();
            canvas.drawPath(path, paint);
          }
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ColorPatternPainter oldDelegate) =>
      label != oldDelegate.label || color != oldDelegate.color;
}

/// A hand-drawn circle/square/triangle/star, used instead of the English
/// shape word so a non-reader can match by sight.
class ShapeGlyph extends StatelessWidget {
  const ShapeGlyph(
      {required this.kind, required this.color, this.size = 40, super.key});
  final String kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case 'circle':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
      case 'square':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(6)),
        );
      case 'triangle':
        return CustomPaint(
          size: Size(size, size),
          painter: TrianglePainter(color),
        );
      case 'star':
        return Icon(Icons.star_rounded, color: color, size: size);
      default:
        return Icon(Icons.crop_square_rounded, color: color, size: size);
    }
  }
}

class TrianglePainter extends CustomPainter {
  TrianglePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// What to say out loud for one option — "three", "blue", "triangle", "B"
/// — just that one short word, not a whole sentence. TTS engines read
/// digit characters as number words on their own, so the option's plain
/// label works as-is for every visual type.
String spokenLabelFor(QuizOption option) => option.label;

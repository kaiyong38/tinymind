import 'package:flutter/material.dart';

import '../models/learning.dart';

/// Renders the visual for a [QuizOption] according to [visual] — a colour
/// swatch, a drawn shape, a big letter over its picture, or a repeated
/// counting emoji — shared by the drag-answer tiles and the teach card.
Widget buildQuizVisual(QuizOption option, AnswerVisual visual,
    {double size = 40}) {
  final fallbackColor = option.color ?? Colors.grey;

  switch (visual) {
    case AnswerVisual.picture:
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            option.emoji ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: size * 0.9),
          ),
        ),
      );
    case AnswerVisual.colorSwatch:
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fallbackColor,
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.black.withValues(alpha: 0.08), width: 2),
        ),
      );
    case AnswerVisual.shape:
      return ShapeGlyph(
        kind: option.label,
        color: fallbackColor,
        size: size,
      );
    case AnswerVisual.letterPicture:
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(option.label,
              style: TextStyle(
                  fontSize: size * 0.48,
                  height: 1,
                  fontWeight: FontWeight.w900)),
          if (option.emoji != null)
            Text(option.emoji!,
                style: TextStyle(fontSize: size * 0.36, height: 1)),
        ],
      );
    case AnswerVisual.numberDots:
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: List.generate(
          option.count ?? 0,
          (_) => Text(option.emoji ?? '•',
              style: TextStyle(fontSize: size * 0.42)),
        ),
      );
    case AnswerVisual.text:
      return Text(option.label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w900));
  }
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

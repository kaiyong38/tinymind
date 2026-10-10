import 'dart:math' as math;

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
      return SizedBox.square(
        dimension: size,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: List.generate(
              option.count ?? 0,
              (_) => option.emoji == null
                  ? Text('•', style: TextStyle(fontSize: size * 0.42))
                  : EmojiGlyph(option.emoji!, size * 0.42),
            ),
          ),
        ),
      );
    case AnswerVisual.colorPair:
      final colorFriendlyPair = context
              .dependOnInheritedWidgetOfExactType<AccessibilitySettingsScope>()
              ?.notifier
              ?.colorFriendlyMode ??
          false;
      final pairNames = option.label.split(' + ');
      final pairDotSize = size * 0.4;
      Widget pairDot(Color color, String name) => Container(
            width: pairDotSize,
            height: pairDotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: colorFriendlyPair
                ? ClipOval(
                    child: CustomPaint(
                      size: Size.square(pairDotSize),
                      painter: ColorPatternPainter(name, color),
                    ),
                  )
                : null,
          );
      return SizedBox.square(
        dimension: size,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                pairDot(option.color ?? Colors.grey, pairNames.first),
                SizedBox(width: size * 0.06),
                pairDot(
                  option.color2 ?? Colors.grey,
                  pairNames.length > 1 ? pairNames[1] : pairNames.first,
                ),
              ],
            ),
          ),
        ),
      );
    case AnswerVisual.shapeCorners:
    case AnswerVisual.shapeSides:
      return SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _ShapeCuePainter(
            ShapeCue(
              _shapeKindFor(option.label),
              markCorners: visual == AnswerVisual.shapeCorners,
              colorSides: visual == AnswerVisual.shapeSides,
            ),
          ),
        ),
      );
    case AnswerVisual.text:
      return Text(option.label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w900));
  }
}

Widget buildQuestionCue(
  QuizCue cue, {
  required double size,
  bool revealDifference = false,
}) {
  return switch (cue) {
    EmojiCue(:final emoji) => EmojiGlyph(emoji, size * 0.76),
    LetterCue(:final text) => _LetterCueView(text: text, size: size),
    ShapeCue() => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _ShapeCuePainter(cue)),
      ),
    ShapeRowCue() => _ShapeRow(cue: cue, size: size, reveal: revealDifference),
    NightSkyCue() => _NightSky(cue: cue, size: size),
    RollingSlopeCue() => _RollingSlopeView(size: size),
    ItemCountCue() => _ItemCountCueView(cue: cue, size: size),
    EquationPictureCue() => _EquationPictureView(cue: cue, size: size),
    TenFrameCue() => _TenFrameView(cue: cue, size: size),
    ColorWordCue() => _ColorWordView(cue: cue, size: size),
    ColorSwatchCue() => _ColorSwatchView(
        name: cue.name,
        color: cue.color,
        diameter: size * 0.85,
      ),
    NumberCue() => _NumberCueView(cue: cue, size: size),
    ColorMixCue() => _ColorMixView(cue: cue, size: size),
    RainbowCue() => _RainbowView(cue: cue, size: size),
  };
}

class _LetterCueView extends StatelessWidget {
  const _LetterCueView({required this.text, required this.size});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                fontSize: 160,
                height: 1,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3A86FF),
              ),
            ),
          ),
        ),
      );
}

class _ColorWordView extends StatelessWidget {
  const _ColorWordView({required this.cue, required this.size});

  final ColorWordCue cue;
  final double size;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(
            constraints.hasBoundedWidth
                ? constraints.maxWidth * 0.9
                : size * 1.8,
            size * 1.8,
          );
          return SizedBox(
            width: width,
            height: width * 0.4,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                cue.name.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: Color(0xFF4A3F3F),
                ),
              ),
            ),
          );
        },
      );
}

class _NumberCueView extends StatelessWidget {
  const _NumberCueView({required this.cue, required this.size});

  final NumberCue cue;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${cue.value}',
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(
                fontSize: 160,
                height: 1,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3A86FF),
              ),
            ),
          ),
        ),
      );
}

class _ItemCountCueView extends StatelessWidget {
  const _ItemCountCueView({required this.cue, required this.size});

  final ItemCountCue cue;
  final double size;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.hasBoundedWidth ? constraints.maxWidth : size;
          final height =
              constraints.hasBoundedHeight ? constraints.maxHeight : size;
          final canvasSize = Size(width, height);
          final rects = cue.itemRectsFor(canvasSize);
          return SizedBox(
            key: ValueKey('item-count-cue-${cue.identityKey}'),
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var index = 0; index < rects.length; index++)
                  Positioned.fromRect(
                    rect: rects[index],
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        EmojiGlyph(cue.emoji, rects[index].width),
                        if (index >= cue.count - cue.removedCount)
                          CustomPaint(painter: _CrossOutPainter()),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

class _EquationPictureView extends StatelessWidget {
  const _EquationPictureView({required this.cue, required this.size});

  final EquationPictureCue cue;
  final double size;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.hasBoundedWidth ? constraints.maxWidth : size;
          final height =
              constraints.hasBoundedHeight ? constraints.maxHeight : size;
          return SizedBox(
            width: width,
            height: height,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _EmojiGroup(emoji: cue.emoji, count: cue.firstCount),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _EmojiGroup(emoji: cue.emoji, count: cue.secondCount),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '=',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const _QuestionBadge(size: 52),
                  ],
                ),
              ),
            ),
          );
        },
      );
}

class _EmojiGroup extends StatelessWidget {
  const _EmojiGroup({required this.emoji, required this.count});

  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: List.generate(count, (_) => EmojiGlyph(emoji, 42)),
      );
}

class _QuestionBadge extends StatelessWidget {
  const _QuestionBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFFE4E7EB),
          shape: BoxShape.circle,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '?',
            style: TextStyle(
              color: const Color(0xFF626B75),
              fontSize: size * 0.7,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      );
}

class _TenFrameView extends StatelessWidget {
  const _TenFrameView({required this.cue, required this.size});

  final TenFrameCue cue;
  final double size;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.hasBoundedWidth ? constraints.maxWidth : size;
          final height =
              constraints.hasBoundedHeight ? constraints.maxHeight : size;
          return CustomPaint(
            size: Size(width, height),
            painter: _TenFramePainter(cue),
          );
        },
      );
}

class _CrossOutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE84855)
      ..strokeWidth = size.shortestSide * 0.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrossOutPainter oldDelegate) => false;
}

class _TenFramePainter extends CustomPainter {
  const _TenFramePainter(this.cue);

  final TenFrameCue cue;

  @override
  void paint(Canvas canvas, Size size) {
    final isTeen = cue.mode == TenFrameMode.teenNumber;
    final boardWidth = isTeen
        ? math.min(size.width * 0.38, size.height * 1.45)
        : math.min(size.width * 0.72, size.height * 1.55);
    final boardHeight = boardWidth * 0.42;
    final gap = size.width * 0.035;
    final boardCount = isTeen ? 2 : 1;
    final totalWidth = boardCount * boardWidth + (boardCount - 1) * gap;
    final left = (size.width - totalWidth) / 2;
    final top = (size.height - boardHeight) / 2 -
        (cue.mode == TenFrameMode.makeTen ? size.height * 0.08 : 0);
    final outline = Paint()
      ..color = const Color(0xFF8A949E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, boardWidth * 0.008);

    for (var board = 0; board < boardCount; board++) {
      final x = left + board * (boardWidth + gap);
      final cellWidth = boardWidth / 5;
      final cellHeight = boardHeight / 2;
      for (var cell = 0; cell < 10; cell++) {
        final rect = Rect.fromLTWH(
          x + (cell % 5) * cellWidth,
          top + (cell ~/ 5) * cellHeight,
          cellWidth,
          cellHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(5)),
          outline,
        );

        final dotKind = _dotKind(board, cell);
        if (dotKind != null) {
          final crossed = cue.mode == TenFrameMode.subtraction &&
              cell >= cue.firstCount - cue.secondCount;
          final center = rect.center;
          final radius = math.min(cellWidth, cellHeight) * 0.28;
          if (dotKind) {
            _paintQuestionDot(canvas, center, radius);
          } else {
            canvas.drawCircle(
              center,
              radius,
              Paint()..color = const Color(0xFFE84855),
            );
          }
          if (crossed) {
            final cross = Paint()
              ..color = const Color(0xFF4A3F3F)
              ..strokeWidth = radius * 0.18
              ..strokeCap = StrokeCap.round;
            canvas.drawLine(
              center - Offset(radius * 0.65, radius * 0.65),
              center + Offset(radius * 0.65, radius * 0.65),
              cross,
            );
            canvas.drawLine(
              center + Offset(radius * 0.65, -radius * 0.65),
              center + Offset(-radius * 0.65, radius * 0.65),
              cross,
            );
          }
        }
      }
    }
  }

  /// null: empty cell, false: red dot, true: "?" dot.
  bool? _dotKind(int board, int cell) {
    if (cue.mode == TenFrameMode.teenNumber) {
      if (board == 0) return false;
      return cell < cue.questionDots ? true : null;
    }
    if (cell < cue.filledDots) return false;
    if (cell < cue.filledDots + cue.questionDots) return true;
    return null;
  }

  void _paintQuestionDot(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFF1EDED));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFB8B0B0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, radius * 0.12),
    );
    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: const Color(0xFF8A8080),
          fontSize: radius * 1.3,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TenFramePainter oldDelegate) =>
      cue.identityKey != oldDelegate.cue.identityKey;
}

class _ColorSwatchView extends StatelessWidget {
  const _ColorSwatchView({
    required this.name,
    required this.color,
    required this.diameter,
  });

  final String name;
  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final friendly = context
            .dependOnInheritedWidgetOfExactType<AccessibilitySettingsScope>()
            ?.notifier
            ?.colorFriendlyMode ??
        false;
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.1), width: 3),
      ),
      child: friendly
          ? ClipOval(
              child: CustomPaint(
                size: Size.square(diameter),
                painter: ColorPatternPainter(name, color),
              ),
            )
          : null,
    );
  }
}

class _MysteryCircle extends StatelessWidget {
  const _MysteryCircle({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) => Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        padding: EdgeInsets.all(diameter * 0.14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EDED),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFB8B0B0), width: 3),
        ),
        child: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '?',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Color(0xFF8A8080),
            ),
          ),
        ),
      );
}

class _ColorMixView extends StatelessWidget {
  const _ColorMixView({required this.cue, required this.size});

  final ColorMixCue cue;
  final double size;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(
            constraints.hasBoundedWidth
                ? constraints.maxWidth * 0.95
                : size * 1.9,
            size * 1.9,
          );
          final diameter = width * 0.2;
          final gap = SizedBox(width: width * 0.03);
          final symbol = TextStyle(
            fontSize: diameter * 0.75,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF4A3F3F),
          );
          return SizedBox(
            width: width,
            height: diameter * 1.2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ColorSwatchView(
                    name: cue.firstName,
                    color: cue.first,
                    diameter: diameter,
                  ),
                  gap,
                  Text('+', style: symbol),
                  gap,
                  _ColorSwatchView(
                    name: cue.secondName,
                    color: cue.second,
                    diameter: diameter,
                  ),
                  gap,
                  Text('=', style: symbol),
                  gap,
                  _MysteryCircle(diameter: diameter),
                ],
              ),
            ),
          );
        },
      );
}

class _RainbowView extends StatelessWidget {
  const _RainbowView({required this.cue, required this.size});

  final RainbowCue cue;
  final double size;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(
            constraints.hasBoundedWidth
                ? constraints.maxWidth * 0.95
                : size * 1.7,
            size * 1.7,
          );
          return SizedBox(
            width: width,
            height: width * 0.56,
            child: CustomPaint(painter: _RainbowPainter(cue)),
          );
        },
      );
}

class _RainbowPainter extends CustomPainter {
  _RainbowPainter(this.cue);

  final RainbowCue cue;

  @override
  void paint(Canvas canvas, Size size) {
    final count = cue.bands.length;
    final center = Offset(size.width / 2, size.height * 0.95);
    final outer = math.min(size.width / 2, size.height * 0.95) - 2;
    final thickness = outer * 0.84 / count;
    Offset? missingTop;
    for (var index = 0; index < count; index++) {
      final radius = outer - thickness * (index + 0.5);
      final missing = index == cue.missingIndex;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness + 0.6
        ..color = missing ? const Color(0xFFE6E1E1) : cue.bands[index];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi,
        false,
        paint,
      );
      if (missing) missingTop = Offset(center.dx, center.dy - radius);
    }
    if (missingTop != null) {
      final badge = thickness * 0.95;
      canvas.drawCircle(missingTop, badge, Paint()..color = Colors.white);
      canvas.drawCircle(
        missingTop,
        badge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = const Color(0xFFB8B0B0),
      );
      final painter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            fontSize: badge * 1.4,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF8A8080),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        missingTop - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainbowPainter oldDelegate) =>
      oldDelegate.cue.missingIndex != cue.missingIndex ||
      oldDelegate.cue.bands != cue.bands;
}

class _ShapeRow extends StatelessWidget {
  const _ShapeRow({
    required this.cue,
    required this.size,
    required this.reveal,
  });

  final ShapeRowCue cue;
  final double size;
  final bool reveal;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final available =
              constraints.hasBoundedWidth ? constraints.maxWidth : size * 1.6;
          final cell = available / cue.shapes.length;
          final glyph = math.min(cell * 0.7, size * 0.62);
          return SizedBox(
            width: available,
            child: Row(
              children: [
                for (var index = 0; index < cue.shapes.length; index++)
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(glyph * 0.12),
                        decoration: reveal && index == cue.differentIndex
                            ? BoxDecoration(
                                border:
                                    Border.all(color: Colors.amber, width: 4),
                                borderRadius: BorderRadius.circular(14),
                              )
                            : null,
                        child: ShapeGlyph(
                          kind: cue.shapes[index].name,
                          color: index == cue.differentIndex
                              ? (cue.differentColor ?? cue.color)
                              : cue.color,
                          size: glyph,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

class _NightSky extends StatelessWidget {
  const _NightSky({required this.cue, required this.size});

  final NightSkyCue cue;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.08),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF182447), Color(0xFF465A85)],
            ),
          ),
          child: cue.showMoon
              ? CustomPaint(painter: _MoonPainter())
              : const SizedBox.expand(),
        ),
      );
}

class _ShapeCuePainter extends CustomPainter {
  _ShapeCuePainter(this.cue);

  final ShapeCue cue;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.shortestSide * (cue.numberSides ? 0.24 : 0.16);
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final vertices = _verticesFor(cue.shape, rect);
    final path = _pathFor(cue.shape, rect, vertices);
    final paintColor = cue.style == CueShapeStyle.silhouette
        ? Colors.blueGrey.shade800
        : cue.color;

    if (cue.colorSides) {
      canvas.drawPath(path, Paint()..color = Colors.white);
      if (vertices.isEmpty) {
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.black45
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.shortestSide * 0.055,
        );
      } else {
        for (var index = 0; index < vertices.length; index++) {
          canvas.drawLine(
            vertices[index],
            vertices[(index + 1) % vertices.length],
            Paint()
              ..color = _sideColors[index % _sideColors.length]
              ..strokeWidth = size.shortestSide * 0.06
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    } else if (cue.style == CueShapeStyle.dashed) {
      final dashedPaint = Paint()
        ..color = paintColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.055
        ..strokeCap = StrokeCap.round;
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        final dash = size.shortestSide * 0.09;
        while (distance < metric.length) {
          canvas.drawPath(
            metric.extractPath(
              distance,
              (distance + dash).clamp(0, metric.length).toDouble(),
            ),
            dashedPaint,
          );
          distance += dash * 1.8;
        }
      }
    } else if (cue.numberSides || cue.markCorners) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black54
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.shortestSide * 0.025,
      );
    } else {
      canvas.drawPath(path, Paint()..color = paintColor);
    }

    if (cue.numberSides && vertices.isNotEmpty) {
      var sum = Offset.zero;
      for (final vertex in vertices) {
        sum += vertex;
      }
      final centroid = sum / vertices.length.toDouble();
      final fontSize = size.shortestSide * 0.12;
      for (var index = 0; index < vertices.length; index++) {
        final start = vertices[index];
        final end = vertices[(index + 1) % vertices.length];
        final midpoint = Offset.lerp(start, end, 0.5)!;
        final outward = midpoint - centroid;
        final length = outward.distance == 0 ? 1.0 : outward.distance;
        final center = midpoint + outward / length * (fontSize * 1.15);
        // Number the sides clockwise, starting from the left side of a triangle.
        final number = vertices.length == 3 ? (index + 1) % 3 + 1 : index + 1;
        canvas.drawCircle(
            center, fontSize * 0.85, Paint()..color = Colors.white);
        canvas.drawCircle(
          center,
          fontSize * 0.85,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = Colors.black26,
        );
        _drawLabel(canvas, '$number', center, fontSize);
      }
    }
    if (cue.markCorners) {
      for (final point in vertices) {
        canvas.drawCircle(
          point,
          size.shortestSide * 0.045,
          Paint()..color = const Color(0xFFE84855),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ShapeCuePainter oldDelegate) =>
      cue != oldDelegate.cue;
}

const _sideColors = [
  Color(0xFF3A86FF),
  Color(0xFFFF8C42),
  Color(0xFF2EC27E),
  Color(0xFFE84855),
];

ShapeKind _shapeKindFor(String label) => switch (label.toLowerCase()) {
      'circle' => ShapeKind.circle,
      'square' => ShapeKind.square,
      'triangle' => ShapeKind.triangle,
      'star' => ShapeKind.star,
      _ => ShapeKind.square,
    };

List<Offset> _verticesFor(ShapeKind shape, Rect rect) {
  switch (shape) {
    case ShapeKind.circle:
      return [];
    case ShapeKind.square:
      return [
        rect.topLeft,
        rect.topRight,
        rect.bottomRight,
        rect.bottomLeft,
      ];
    case ShapeKind.triangle:
      return [
        Offset(rect.center.dx, rect.top),
        rect.bottomRight,
        rect.bottomLeft,
      ];
    case ShapeKind.star:
      return List.generate(10, (index) {
        final angle = -math.pi / 2 + index * math.pi / 5;
        final radius = rect.shortestSide * (index.isEven ? 0.5 : 0.22);
        return Offset(
          rect.center.dx + math.cos(angle) * radius,
          rect.center.dy + math.sin(angle) * radius,
        );
      });
  }
}

Path _pathFor(ShapeKind shape, Rect rect, List<Offset> vertices) {
  if (shape == ShapeKind.circle) return Path()..addOval(rect);
  final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
  for (final point in vertices.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

void _drawLabel(Canvas canvas, String label, Offset center, double fontSize) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.black87,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    center - Offset(painter.width / 2, painter.height / 2),
  );
}

class _NightSkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.42),
      size.shortestSide * 0.18,
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.drawCircle(
      Offset(size.width * 0.77, size.height * 0.34),
      size.shortestSide * 0.17,
      Paint()..color = const Color(0xFF263B66),
    );
  }

  @override
  bool shouldRepaint(covariant _NightSkyPainter oldDelegate) => false;
}

class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    _NightSkyPainter().paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) => false;
}

class _RollingSlopeView extends StatelessWidget {
  const _RollingSlopeView({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width =
              constraints.hasBoundedWidth ? constraints.maxWidth : size;
          final height =
              constraints.hasBoundedHeight ? constraints.maxHeight : size;
          return CustomPaint(
            size: Size(width, height),
            painter: _RollingSlopePainter(),
          );
        },
      );
}

class _RollingSlopePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final groundY = size.height * 0.82;
    final slopeTop = Offset(size.width * 0.1, size.height * 0.14);
    final slopeFoot = Offset(size.width * 0.72, groundY);
    final groundPaint = Paint()..color = const Color(0xFFDDF2D5);
    canvas.drawRect(
      Rect.fromLTRB(0, groundY, size.width, size.height),
      groundPaint,
    );

    final slope = Path()
      ..moveTo(slopeTop.dx, slopeTop.dy)
      ..lineTo(slopeFoot.dx, slopeFoot.dy)
      ..lineTo(slopeTop.dx, groundY)
      ..close();
    canvas.drawPath(slope, Paint()..color = const Color(0xFFD7B28A));

    final slopeVector = slopeFoot - slopeTop;
    final slopeLength = slopeVector.distance;
    final direction = slopeVector / slopeLength;
    final normal = Offset(direction.dy, -direction.dx);
    final shortSide = size.shortestSide;

    final speedPaint = Paint()
      ..color = const Color(0xFF72543D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortSide * 0.025
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      final t = 0.12 + index * 0.09;
      final start = slopeTop + slopeVector * t + normal * (shortSide * 0.055);
      final end = start + direction * (shortSide * 0.075);
      final curve = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          start.dx +
              direction.dx * shortSide * 0.035 +
              normal.dx * shortSide * 0.025,
          start.dy +
              direction.dy * shortSide * 0.035 +
              normal.dy * shortSide * 0.025,
          end.dx,
          end.dy,
        );
      canvas.drawPath(curve, speedPaint);
    }

    final arrowStart = slopeTop + slopeVector * 0.36;
    final arrowTip = slopeTop + slopeVector * 0.76;
    final arrowPaint = Paint()
      ..color = const Color(0xFF4E3B2D)
      ..strokeWidth = shortSide * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(arrowStart, arrowTip, arrowPaint);
    final arrowHeadLength = shortSide * 0.12;
    final arrowHeadHalfWidth = shortSide * 0.075;
    for (final side in [-1.0, 1.0]) {
      final headEnd = arrowTip -
          direction * arrowHeadLength +
          normal * (arrowHeadHalfWidth * side);
      canvas.drawLine(arrowTip, headEnd, arrowPaint);
    }

    final dashPaint = Paint()
      ..color = const Color(0xFF72543D)
      ..strokeWidth = shortSide * 0.022
      ..strokeCap = StrokeCap.round;
    final dashLength = shortSide * 0.07;
    final dashGap = shortSide * 0.045;
    for (var x = slopeFoot.dx + size.width * 0.025;
        x < size.width * 0.97;
        x += dashLength + dashGap) {
      canvas.drawLine(
        Offset(x, groundY),
        Offset(math.min(x + dashLength, size.width * 0.98), groundY),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RollingSlopePainter oldDelegate) => false;
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

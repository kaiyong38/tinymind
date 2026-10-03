import 'package:flutter/material.dart';

import '../models/learning.dart';
import '../services/narration_service.dart';
import 'quiz_visuals.dart';

/// A controlled (stateless) drag-and-drop answer area: one empty slot the
/// child drags a tile into, with the tray of draggable option tiles below
/// it. Replaces the old tap-a-pill mechanic everywhere — letters, numbers,
/// shapes and colours all answer the same way now.
///
/// Dragging a tile (or just tapping it, for a no-commitment "what is
/// this?" preview) speaks that one option's name aloud — "three", "blue",
/// "triangle" — via [NarrationService]. Dropping a tile into the slot
/// reports the pick back through [onDrop]; this widget never decides
/// right/wrong itself; [answered]/[selectedIndex] come from the parent so
/// a "try again" reset is just a rebuild, no separate state to desync.
class DragAnswerArea extends StatelessWidget {
  const DragAnswerArea({
    required this.question,
    required this.selectedIndex,
    required this.answered,
    required this.moduleColor,
    required this.onDrop,
    super.key,
  });

  final QuizQuestion question;
  final int? selectedIndex;
  final bool answered;
  final Color moduleColor;
  final void Function(int index) onDrop;

  bool get _isCorrect => answered && selectedIndex == question.answerIndex;
  bool get _isWrong => answered && selectedIndex != null && !_isCorrect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final tileSize = ((constraints.maxHeight - 12) / 2.2)
          .clamp(52.0, 84.0)
          .toDouble();
      final slotSize = tileSize * 1.15;
      final slot = _Slot(
        option: selectedIndex == null ? null : question.options[selectedIndex!],
        visual: question.visual,
        correct: _isCorrect,
        wrong: _isWrong,
        moduleColor: moduleColor,
        size: slotSize,
      );
      final tray = Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < question.options.length; i++)
            _Tile(
              index: i,
              option: question.options[i],
              visual: question.visual,
              moduleColor: moduleColor,
              // A tile that's currently sitting in the slot fades out of
              // the tray instead of sitting there twice.
              placed: selectedIndex == i,
              draggable: !answered,
              size: tileSize,
            ),
        ],
      );
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DragTarget<int>(
                onWillAcceptWithDetails: (_) => !answered,
                onAcceptWithDetails: (details) => onDrop(details.data),
                builder: (context, candidates, rejected) =>
                    candidates.isNotEmpty ? slot.highlighted() : slot,
              ),
              const SizedBox(height: 12),
              tray,
            ],
          ),
        ),
      );
    });
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.option,
    required this.visual,
    required this.correct,
    required this.wrong,
    required this.moduleColor,
    required this.size,
    this.highlight = false,
  });

  final QuizOption? option;
  final AnswerVisual visual;
  final bool correct;
  final bool wrong;
  final Color moduleColor;
  final double size;
  final bool highlight;

  _Slot highlighted() => _Slot(
        option: option,
        visual: visual,
        correct: correct,
        wrong: wrong,
        moduleColor: moduleColor,
        size: size,
        highlight: true,
      );

  @override
  Widget build(BuildContext context) {
    final borderColor = correct
        ? Colors.green
        : wrong
            ? Colors.red
            : highlight
                ? moduleColor
                : Colors.black26;
    final fillColor = correct
        ? Colors.green.withValues(alpha: 0.12)
        : wrong
            ? Colors.red.withValues(alpha: 0.12)
            : option != null
                ? moduleColor.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.04);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 3),
      ),
      child: option == null
          ? Icon(Icons.north_rounded,
              color: Colors.black26, size: size * 0.3)
          : Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(size * 0.09),
                  child: buildQuizVisual(option!, visual, size: size * 0.72),
                ),
                if (correct || wrong)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        correct ? Icons.check_circle : Icons.cancel,
                        color: correct ? Colors.green : Colors.red,
                        size: size * 0.25,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.index,
    required this.option,
    required this.visual,
    required this.moduleColor,
    required this.placed,
    required this.draggable,
    required this.size,
  });

  final int index;
  final QuizOption option;
  final AnswerVisual visual;
  final Color moduleColor;
  final bool placed;
  final bool draggable;
  final double size;

  void _preview() => NarrationService.instance.speak(spokenLabelFor(option));

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: moduleColor.withValues(alpha: 0.5), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: buildQuizVisual(option, visual, size: size * 0.65),
    );

    if (placed) {
      // Still occupies its spot in the tray (keeps the layout stable) but
      // fades out since the same tile is now shown, full-strength, in the
      // slot above.
      return Opacity(opacity: 0.25, child: card);
    }

    return Draggable<int>(
      data: index,
      maxSimultaneousDrags: draggable ? 1 : 0,
      onDragStarted: _preview,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.1, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: GestureDetector(
        onTap: _preview,
        child: card,
      ),
    );
  }
}

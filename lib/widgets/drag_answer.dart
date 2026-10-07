import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/learning.dart';
import '../services/accessibility_settings.dart';
import '../services/narration_service.dart';
import '../theme/adaptive_metrics.dart';
import 'quiz_visuals.dart';

/// A controlled answer area that supports both dragging and tapping options.
/// A tap previews and selects an option; tapping it again or the answer slot
/// confirms it through the same callback used by drag-and-drop.
class DragAnswerArea extends StatefulWidget {
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

  @override
  State<DragAnswerArea> createState() => _DragAnswerAreaState();
}

class _DragAnswerAreaState extends State<DragAnswerArea>
    with TickerProviderStateMixin {
  late List<GlobalKey> _tileKeys;
  final GlobalKey _slotKey = GlobalKey(debugLabel: 'drag-answer-slot');
  late final AnimationController _flightController;
  late final AnimationController _hintController;
  OverlayEntry? _flightEntry;
  int? _tapSelectedIndex;
  int? _flightIndex;
  bool _animating = false;
  bool _submitted = false;

  bool get _interactionLocked => widget.answered || _animating || _submitted;

  @override
  void initState() {
    super.initState();
    _tileKeys = _createTileKeys();
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      lowerBound: 0.4,
      upperBound: 1,
    );
  }

  List<GlobalKey> _createTileKeys() => List.generate(
        widget.question.options.length,
        (index) => GlobalKey(debugLabel: 'drag-answer-option-$index'),
      );

  @override
  void didUpdateWidget(covariant DragAnswerArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question ||
        oldWidget.answered && !widget.answered) {
      _tapSelectedIndex = null;
      _submitted = false;
      _flightIndex = null;
      _hintController.stop();
      _hintController.value = _hintController.lowerBound;
      if (oldWidget.question.options.length != widget.question.options.length) {
        _tileKeys = _createTileKeys();
      }
    }
  }

  @override
  void dispose() {
    _flightEntry?.remove();
    _flightEntry?.dispose();
    _flightController.dispose();
    _hintController.dispose();
    super.dispose();
  }

  void _activateOption(int index) {
    if (_interactionLocked) return;
    if (_tapSelectedIndex == index) {
      _confirmSelection(index);
      return;
    }

    NarrationService.instance
        .speak(spokenLabelFor(widget.question.options[index]));
    setState(() => _tapSelectedIndex = index);
    _hintController.repeat(reverse: true);
  }

  void _acceptDrop(int index) {
    if (_interactionLocked) return;
    _submitted = true;
    _tapSelectedIndex = null;
    _hintController.stop();
    widget.onDrop(index);
  }

  Future<void> _confirmSelection(int index) async {
    if (_interactionLocked) return;
    final tileObject = _tileKeys[index].currentContext?.findRenderObject();
    final slotObject = _slotKey.currentContext?.findRenderObject();
    final overlay = Overlay.maybeOf(context);
    final overlayObject = overlay?.context.findRenderObject();
    if (tileObject is! RenderBox ||
        slotObject is! RenderBox ||
        overlayObject is! RenderBox ||
        overlay == null) {
      _acceptDrop(index);
      return;
    }

    final start =
        tileObject.localToGlobal(Offset.zero, ancestor: overlayObject) &
            tileObject.size;
    final end = slotObject.localToGlobal(Offset.zero, ancestor: overlayObject) &
        slotObject.size;
    final option = widget.question.options[index];
    final visual = widget.question.visual;
    final color = widget.moduleColor;
    setState(() {
      _animating = true;
      _flightIndex = index;
    });

    final entry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: _flightController,
        builder: (context, child) {
          final rect = Rect.lerp(start, end, _flightController.value)!;
          return Positioned.fromRect(rect: rect, child: child!);
        },
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: start.width,
              height: start.height,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: color.withValues(alpha: 0.5), width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: buildQuizVisual(
                context,
                option,
                visual,
                size: visual == AnswerVisual.colorSwatch
                    ? start.width - 16
                    : start.width * 0.65,
              ),
            ),
          ),
        ),
      ),
    );

    _flightEntry = entry;
    overlay.insert(entry);
    try {
      await _flightController.forward();
    } finally {
      if (identical(_flightEntry, entry)) {
        _flightEntry = null;
        entry.remove();
        entry.dispose();
      }
      _flightController.reset();
      if (mounted) {
        setState(() {
          _animating = false;
          _flightIndex = null;
        });
      }
    }

    if (!mounted || widget.answered || _submitted) return;
    _submitted = true;
    _tapSelectedIndex = null;
    _hintController.stop();
    widget.onDrop(index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final colorFriendly =
          widget.question.visual == AnswerVisual.colorSwatch &&
              AccessibilitySettingsScope.of(context).colorFriendlyMode;
      final metrics = AdaptiveMetrics.fromConstraints(context, constraints);
      final minTileSize = colorFriendly
          ? 76.0
          : metrics.size(56).clamp(56.0, double.infinity).toDouble();
      final maxTileSize = (metrics.size(104)).clamp(minTileSize, 132.0);
      final gap = metrics.size(16);
      final optionCount = widget.question.options.length;
      final heightLimit = (constraints.maxHeight - gap) / 1.95;
      final widthLimit =
          (constraints.maxWidth - gap * (optionCount - 1)) / optionCount;
      final tileSize = math
          .min(heightLimit, widthLimit)
          .clamp(minTileSize, maxTileSize)
          .toDouble();
      final slotSize = tileSize * 0.95;
      final displayedIndex = widget.selectedIndex ?? _tapSelectedIndex;
      final slot = _Slot(
        option: displayedIndex == null
            ? null
            : widget.question.options[displayedIndex],
        visual: widget.question.visual,
        correct: widget.answered &&
            widget.selectedIndex == widget.question.answerIndex,
        wrong: widget.answered &&
            widget.selectedIndex != null &&
            widget.selectedIndex != widget.question.answerIndex,
        moduleColor: widget.moduleColor,
        size: slotSize,
        targetKey: _slotKey,
        hint: _tapSelectedIndex != null && !widget.answered,
        hintOpacity: _hintController.value,
        onTap: _tapSelectedIndex == null || _interactionLocked
            ? null
            : () => _confirmSelection(_tapSelectedIndex!),
      );
      final tray = Wrap(
        alignment: WrapAlignment.center,
        spacing: metrics.size(16),
        runSpacing: metrics.size(16),
        children: [
          for (var i = 0; i < widget.question.options.length; i++)
            _Tile(
              key: _tileKeys[i],
              index: i,
              option: widget.question.options[i],
              visual: widget.question.visual,
              moduleColor: widget.moduleColor,
              placed: widget.selectedIndex == i,
              selected: _tapSelectedIndex == i,
              inFlight: _flightIndex == i,
              draggable: !_interactionLocked,
              enabled: !_interactionLocked,
              size: tileSize,
              onTap: () => _activateOption(i),
            ),
        ],
      );
      return SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DragTarget<int>(
                    key: const ValueKey('drag-answer-slot'),
                    onWillAcceptWithDetails: (_) => !_interactionLocked,
                    onAcceptWithDetails: (details) => _acceptDrop(details.data),
                    builder: (context, candidates, rejected) {
                      final target =
                          candidates.isNotEmpty ? slot.highlighted() : slot;
                      return AnimatedBuilder(
                        animation: _hintController,
                        builder: (context, child) => Opacity(
                          opacity: slot.hint ? _hintController.value : 1,
                          child: child,
                        ),
                        child: target,
                      );
                    },
                  ),
                  SizedBox(height: metrics.size(16)),
                  tray,
                ],
              ),
            ),
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
    required this.hint,
    required this.hintOpacity,
    required this.onTap,
    required this.targetKey,
    this.highlight = false,
  });

  final GlobalKey targetKey;
  final QuizOption? option;
  final AnswerVisual visual;
  final bool correct;
  final bool wrong;
  final Color moduleColor;
  final double size;
  final bool hint;
  final double hintOpacity;
  final VoidCallback? onTap;
  final bool highlight;

  _Slot highlighted() => _Slot(
        option: option,
        visual: visual,
        correct: correct,
        wrong: wrong,
        moduleColor: moduleColor,
        size: size,
        hint: hint,
        hintOpacity: hintOpacity,
        onTap: onTap,
        targetKey: targetKey,
        highlight: true,
      );

  @override
  Widget build(BuildContext context) {
    final borderColor = correct
        ? Colors.green
        : wrong
            ? Colors.red
            : highlight || hint
                ? moduleColor
                : Colors.black26;
    final fillColor = correct
        ? Colors.green.withValues(alpha: 0.12)
        : wrong
            ? Colors.red.withValues(alpha: 0.12)
            : option != null
                ? moduleColor.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.04);
    return GestureDetector(
      key: targetKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        key: const ValueKey('drag-answer-slot-target'),
        width: size,
        height: size,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: hint ? 4 : 3),
          ),
          child: option == null
              ? Opacity(
                  opacity: hint ? hintOpacity : 1,
                  child: Icon(
                    hint ? Icons.touch_app_rounded : Icons.north_rounded,
                    color: hint ? moduleColor : Colors.black26,
                    size: size * 0.3,
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(size * 0.09),
                      child: buildQuizVisual(
                        context,
                        option!,
                        visual,
                        size: size -
                            2 *
                                (visual == AnswerVisual.colorSwatch
                                    ? size * 0.06
                                    : size * 0.09),
                      ),
                    ),
                    if (correct || wrong)
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            correct ? Icons.check_circle : Icons.cancel,
                            color: correct ? Colors.green : Colors.red,
                            size: size * 0.25,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.index,
    required this.option,
    required this.visual,
    required this.moduleColor,
    required this.placed,
    required this.selected,
    required this.inFlight,
    required this.draggable,
    required this.enabled,
    required this.size,
    required this.onTap,
  });

  final int index;
  final QuizOption option;
  final AnswerVisual visual;
  final Color moduleColor;
  final bool placed;
  final bool selected;
  final bool inFlight;
  final bool draggable;
  final bool enabled;
  final double size;
  final VoidCallback onTap;

  void _preview() => NarrationService.instance.speak(spokenLabelFor(option));

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      key: ValueKey('drag-answer-option-card-$index'),
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: selected ? moduleColor.withValues(alpha: 0.15) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? moduleColor : moduleColor.withValues(alpha: 0.5),
          width: selected ? 4 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                selected ? moduleColor.withValues(alpha: 0.24) : Colors.black12,
            blurRadius: selected ? 9 : 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: buildQuizVisual(
        context,
        option,
        visual,
        size: visual == AnswerVisual.colorSwatch ? size - 12 : size - 12,
      ),
    );

    final tile = SizedBox(
      width: size,
      height: size,
      child: Semantics(
        key: ValueKey('drag-answer-option-$index'),
        button: true,
        label: 'Option: ${spokenLabelFor(option)}, double tap to answer',
        onTap: enabled ? onTap : null,
        child: ExcludeSemantics(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onTap : null,
            child: AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack,
              child: card,
            ),
          ),
        ),
      ),
    );

    if (placed) {
      return Opacity(opacity: 0.25, child: tile);
    }

    return Opacity(
      opacity: inFlight ? 0.2 : 1,
      child: Draggable<int>(
        data: index,
        maxSimultaneousDrags: draggable ? 1 : 0,
        onDragStarted: _preview,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(scale: 1.1, child: card),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: tile),
        child: tile,
      ),
    );
  }
}

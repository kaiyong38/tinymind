import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/learning.dart';
import '../theme/adaptive_metrics.dart';
import 'emoji_glyph.dart';
import 'quiz_visuals.dart';

class QuestionCueCard extends StatelessWidget {
  const QuestionCueCard({
    required this.question,
    required this.worldColor,
    required this.onReplay,
    this.revealDifference = false,
    super.key,
  });

  final QuizQuestion question;
  final Color worldColor;
  final VoidCallback onReplay;
  final bool revealDifference;

  static const _speakerSize = 26.0;
  // Keeps the prompt text clear of the speaker, symmetric so it stays centred.
  static const _speakerGutter = 34.0;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Hear the question again',
        child: Card(
          elevation: 0,
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onReplay,
            child: Stack(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _content(),
                ),
                Positioned(
                  right: 6,
                  bottom: 4,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: _speakerSize,
                      color: worldColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _content() => LayoutBuilder(
        builder: (context, constraints) {
          final metrics = AdaptiveMetrics.fromConstraints(context, constraints);
          final cue = question.cue;
          final cueSize = math.min(
            constraints.maxWidth * 0.8,
            constraints.maxHeight * 0.7,
          );
          const promptPadding =
              EdgeInsets.symmetric(horizontal: _speakerGutter - 12);
          if (cue == null) {
            return Padding(
              padding: promptPadding,
              child: Center(
                child: EmojiText(
                  question.prompt,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: metrics.size(22),
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                flex: 8,
                child: Center(
                  child: buildQuestionCue(
                    cue,
                    size: cueSize,
                    revealDifference: revealDifference,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: promptPadding,
                  child: Center(
                    child: Text(
                      question.prompt,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: metrics.size(20),
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

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

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onReplay,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final metrics =
                    AdaptiveMetrics.fromConstraints(context, constraints);
                final cue = question.cue;
                // The read-aloud button lives in the page header, so the cue can
                // use the whole card.
                final cueSize = math.min(
                  constraints.maxWidth * 0.8,
                  constraints.maxHeight * 0.7,
                );
                if (cue == null) {
                  return Column(
                    children: [
                      Expanded(
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
                      ),
                    ],
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
                  ],
                );
              },
            ),
          ),
        ),
      );
}

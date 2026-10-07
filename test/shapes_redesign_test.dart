import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/tts_text_helper.dart';
import 'package:tinymind/widgets/question_cue_card.dart';
import 'package:tinymind/widgets/quiz_visuals.dart';

void main() {
  final shapeActivities = worldCatalogs['shapes']!.activities;

  test('all Shapes questions have a cue and clean spokenText', () {
    for (final activity in shapeActivities) {
      for (final question in activity.questions) {
        expect(question.cue, isNotNull, reason: activity.id);
        expect(question.playType, isNotNull, reason: activity.id);
        expect(question.spokenText, isNotEmpty, reason: activity.id);
        final spoken = TtsTextHelper.clean(question.spokenText!);
        expect(
          spoken.runes.any(_isEmoji),
          isFalse,
          reason: '${activity.id}: $spoken',
        );
      }
    }
  });

  test('no activity repeats the same prompt, cue, and correct answer', () {
    for (final activity in shapeActivities) {
      final tuples = <String>{};
      for (final question in activity.questions) {
        final correct = question.options[question.answerIndex];
        final tuple = [
          question.prompt,
          question.cue!.identityKey,
          correct.identityKeyFor(question.visual),
        ].join('|');
        expect(
          tuples.add(tuple),
          isTrue,
          reason: '${activity.id} repeats $tuple',
        );
      }
    }
  });

  test('non-pair prompts and speech do not reveal the correct option name', () {
    for (final activity in shapeActivities) {
      for (final question in activity.questions) {
        final correct = question.options[question.answerIndex];
        if (question.playType == PlayType.lookListen ||
            question.playType == PlayType.findSame) {
          if (int.tryParse(correct.label) != null) {
            expect(
              question.prompt,
              isNot(contains(correct.label)),
              reason: '${activity.id} prompt reveals ${correct.label}',
            );
          }
          continue;
        }
        expect(
          _containsPhrase(question.prompt, correct.label),
          isFalse,
          reason: '${activity.id} prompt reveals ${correct.label}',
        );
        expect(
          _containsPhrase(question.spokenText!, correct.label),
          isFalse,
          reason: '${activity.id} speech reveals ${correct.label}',
        );
        final answerNumber = int.tryParse(correct.label);
        if (answerNumber != null) {
          final numberWord = const {
            0: 'zero',
            1: 'one',
            2: 'two',
            3: 'three',
            4: 'four',
            5: 'five',
          }[answerNumber];
          if (numberWord != null) {
            expect(
              _containsPhrase(question.spokenText!, numberWord),
              isFalse,
              reason: '${activity.id} speech reveals $numberWord',
            );
          }
        }
      }
    }
  });

  test('non-pair cue identities do not equal correct option identities', () {
    for (final activity in shapeActivities) {
      for (final question in activity.questions) {
        if (question.playType == PlayType.lookListen ||
            question.playType == PlayType.findSame ||
            question.playType == PlayType.concept) {
          continue;
        }
        final correct = question.options[question.answerIndex];
        expect(
          question.cue!.identityKey,
          isNot(correct.identityKeyFor(question.visual)),
          reason: activity.id,
        );
      }
    }
  });

  test('Shapes prompts use at most three words', () {
    for (final activity in shapeActivities) {
      for (final question in activity.questions) {
        final words = question.prompt
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .length;
        expect(words, lessThanOrEqualTo(3), reason: activity.id);
      }
    }
  });

  test('number-answer prompts do not contain the correct number', () {
    for (final question
        in shapeActivities.expand((activity) => activity.questions)) {
      final correct = question.options[question.answerIndex];
      if (int.tryParse(correct.label) == null) continue;
      expect(
        question.prompt,
        isNot(contains(correct.label)),
        reason: question.prompt,
      );
    }
  });

  test('shape-to-object distractors have a clearly different shape', () {
    const distractorShapes = {
      'Gift': 'square',
      'Tent': 'triangle',
      'Ball': 'round',
      'Cookie': 'round',
      'Pizza slice': 'triangle',
      'Box': 'square',
      'Orange': 'round',
      'Moon': 'round',
      'Picture frame': 'square',
      'Cheese': 'triangle',
    };
    for (final activity in shapeActivities) {
      for (final question in activity.questions) {
        if (question.playType != PlayType.realWorld ||
            question.cue is! ShapeCue) {
          continue;
        }
        final cueShape = (question.cue! as ShapeCue).shape;
        final correct = question.options[question.answerIndex];
        final correctShape = distractorShapes[correct.label];
        if (correctShape == null) continue;
        expect(
          correctShape,
          _shapeCategory(cueShape),
          reason: '${activity.id}: ${correct.label} does not match its cue',
        );
        for (var index = 0; index < question.options.length; index++) {
          if (index == question.answerIndex) continue;
          final distractor = question.options[index];
          final distractorShape = distractorShapes[distractor.label];
          expect(
            distractorShape,
            isNot(_shapeCategory(cueShape)),
            reason: '${activity.id}: ${distractor.label} is also a match',
          );
        }
      }
    }
  });

  testWidgets('question card tap replays; odd shape reveals later',
      (tester) async {
    final question = shapeActivities
        .singleWhere((activity) => activity.id == 'shapes_10')
        .questions
        .first;
    var replayCount = 0;

    Widget card({bool reveal = false}) => MaterialApp(
          home: Scaffold(
            body: QuestionCueCard(
              question: question,
              worldColor: Colors.teal,
              onReplay: () => replayCount++,
              revealDifference: reveal,
            ),
          ),
        );

    await tester.pumpWidget(card());
    final highlightedShape = find.byWidgetPredicate((widget) {
      if (widget is! Container || widget.decoration is! BoxDecoration) {
        return false;
      }
      return (widget.decoration! as BoxDecoration).border?.top.color ==
          Colors.amber;
    });
    expect(highlightedShape, findsNothing);

    await tester.tap(find.text('Odd one out?'));
    await tester.pump();
    expect(replayCount, 1);

    // The read-aloud button lives in the page header, not in the card.
    expect(find.byTooltip('Read question again'), findsNothing);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);

    await tester.pumpWidget(card(reveal: true));
    expect(highlightedShape, findsOneWidget);
  });

  test('Moon is no longer used as an answer picture in Shapes', () {
    for (final activity in shapeActivities) {
      for (final question in activity.questions) {
        for (final option in question.options) {
          expect(option.emoji, isNot('🌕'), reason: activity.id);
        }
      }
    }
  });

  test('odd one out: the different shape has its own colour', () {
    final activity = shapeActivities.singleWhere((a) => a.id == 'shapes_10');
    for (final question in activity.questions) {
      final cue = question.cue! as ShapeRowCue;
      expect(cue.differentColor, isNotNull);
      expect(cue.differentColor, isNot(cue.color));
      final correct = question.options[question.answerIndex];
      expect(correct.color, cue.differentColor, reason: question.prompt);
    }
  });

  test('shapes_12 shows a number and marks the corners or sides on the answers',
      () {
    final activity = shapeActivities.singleWhere((a) => a.id == 'shapes_12');
    final corners = activity.questions[0];
    final sides = activity.questions[2];
    expect((corners.cue! as NumberCue).value, 4);
    expect(corners.visual, AnswerVisual.shapeCorners);
    expect(corners.options[corners.answerIndex].label, 'square');
    expect((sides.cue! as NumberCue).value, 3);
    expect(sides.visual, AnswerVisual.shapeSides);
    expect(sides.options[sides.answerIndex].label, 'triangle');
  });

  test('first-question speech is a question, not the intro sentence', () {
    for (final activity in shapeActivities) {
      final first = activity.questions.first;
      expect(first.spokenText, isNot(startsWith('This is a')),
          reason: activity.id);
    }
  });

  testWidgets('answer pictures with marked corners, sides and pairs render',
      (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget visual(AnswerVisual kind, QuizOption option) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) =>
                    buildQuizVisual(context, option, kind, size: 80),
              ),
            ),
          ),
        );

    for (final label in ['circle', 'triangle', 'square']) {
      await tester.pumpWidget(
          visual(AnswerVisual.shapeCorners, QuizOption(label)));
      expect(tester.takeException(), isNull, reason: 'corners $label');
      await tester.pumpWidget(
          visual(AnswerVisual.shapeSides, QuizOption(label)));
      expect(tester.takeException(), isNull, reason: 'sides $label');
    }
    await tester.pumpWidget(visual(
      AnswerVisual.colorPair,
      const QuizOption('Red + Yellow',
          color: Color(0xFFE84855), color2: Color(0xFFFFC93C)),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('triangle in the odd-one-out row is not squeezed',
      (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final question = shapeActivities
        .singleWhere((a) => a.id == 'shapes_10')
        .questions
        .first;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 170,
              child: QuestionCueCard(
                question: question,
                worldColor: Colors.green,
                onReplay: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final triangle = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is TrianglePainter,
    );
    expect(triangle, findsWidgets);
    final size = tester.getSize(triangle.first);
    expect(size.width, closeTo(size.height, 1));
    expect(tester.takeException(), isNull);
  });
}

String _shapeCategory(ShapeKind shape) => switch (shape) {
      ShapeKind.circle => 'round',
      ShapeKind.square => 'square',
      ShapeKind.triangle => 'triangle',
      ShapeKind.star => 'star',
    };

bool _containsPhrase(String text, String phrase) {
  final escaped = RegExp.escape(phrase.toLowerCase());
  return RegExp(
    '(?<![a-z0-9])$escaped(?![a-z0-9])',
    caseSensitive: false,
  ).hasMatch(text);
}

bool _isEmoji(int rune) =>
    (rune >= 0x1F000 && rune <= 0x1FAFF) || (rune >= 0x2600 && rune <= 0x27BF);

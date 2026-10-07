import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/tts_text_helper.dart';
import 'package:tinymind/widgets/question_cue_card.dart';

void main() {
  final colorActivities = worldCatalogs['colors']!.activities;
  final questions =
      colorActivities.expand((activity) => activity.questions).toList();

  test('all Colors questions have a cue, play type, and clean spokenText', () {
    for (final activity in colorActivities) {
      for (final question in activity.questions) {
        expect(question.cue, isNotNull, reason: activity.id);
        expect(question.playType, isNotNull, reason: activity.id);
        expect(question.spokenText, isNotEmpty, reason: activity.id);
        final spoken = TtsTextHelper.clean(question.spokenText!);
        expect(spoken.runes.any(_isEmoji), isFalse,
            reason: '${activity.id}: $spoken');
      }
    }
  });

  test('Colors prompts use at most three words', () {
    for (final activity in colorActivities) {
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

  test('hints are short and the first question is the only teaching step', () {
    for (final activity in colorActivities) {
      final qs = activity.questions;
      expect(qs[0].teach, isNotNull, reason: activity.id);
      expect(qs[0].teachOption, isNotNull, reason: activity.id);
      expect(qs[1].teach, isNull, reason: activity.id);
      expect(qs[2].teach, isNull, reason: activity.id);
      for (final question in qs) {
        final hintWords = (question.hint ?? '')
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .length;
        expect(hintWords, lessThanOrEqualTo(6), reason: activity.id);
      }
    }
  });

  test('no activity repeats the same prompt, cue, and correct answer', () {
    for (final activity in colorActivities) {
      final tuples = <String>{};
      for (final question in activity.questions) {
        final correct = question.options[question.answerIndex];
        final tuple = [
          question.prompt,
          question.cue!.identityKey,
          correct.identityKeyFor(question.visual),
        ].join('|');
        expect(tuples.add(tuple), isTrue,
            reason: '${activity.id} repeats $tuple');
      }
    }
  });

  test('non-pair prompts and speech do not reveal the correct option name', () {
    for (final activity in colorActivities) {
      for (final question in activity.questions) {
        if (question.playType == PlayType.lookListen ||
            question.playType == PlayType.findSame) {
          continue;
        }
        final correct = question.options[question.answerIndex];
        expect(_containsPhrase(question.prompt, correct.label), isFalse,
            reason: '${activity.id} prompt reveals ${correct.label}');
        expect(_containsPhrase(question.spokenText!, correct.label), isFalse,
            reason: '${activity.id} speech reveals ${correct.label}');
      }
    }
  });

  test('cue identity never equals the correct option for real-world questions',
      () {
    for (final activity in colorActivities) {
      for (final question in activity.questions) {
        if (question.playType != PlayType.realWorld) continue;
        final correct = question.options[question.answerIndex];
        expect(question.cue!.identityKey,
            isNot(correct.identityKeyFor(question.visual)),
            reason: activity.id);
      }
    }
  });

  test('object cues are unique across the Colors world', () {
    final emojis = <String>[];
    for (final question in questions) {
      final cue = question.cue;
      if (cue is EmojiCue) emojis.add(cue.emoji);
    }
    expect(emojis.toSet().length, emojis.length, reason: emojis.join(' '));
  });

  test('basic color activities teach, match, and name the same color', () {
    for (var number = 1; number <= 8; number++) {
      final activity = colorActivities[number - 1];
      final color = activity.title;
      final q1 = activity.questions[0];
      final q2 = activity.questions[1];
      final q3 = activity.questions[2];
      expect((q1.cue! as ColorWordCue).name, color, reason: activity.id);
      expect(q1.options[q1.answerIndex].label, color, reason: activity.id);
      expect((q2.cue! as ColorSwatchCue).name, color, reason: activity.id);
      expect(q2.visual, AnswerVisual.picture, reason: activity.id);
      expect(q3.cue, isA<EmojiCue>(), reason: activity.id);
      expect(q3.options[q3.answerIndex].label, color, reason: activity.id);
    }
  });

  test('mixing activities follow real paint mixing', () {
    const mix = {
      'red+yellow': 'orange',
      'blue+yellow': 'green',
      'red+blue': 'purple',
    };
    for (final id in ['colors_09', 'colors_10', 'colors_11']) {
      final activity = colorActivities.singleWhere((a) => a.id == id);
      final q1 = activity.questions[0];
      final cue = q1.cue! as ColorMixCue;
      final key =
          '${cue.firstName.toLowerCase()}+${cue.secondName.toLowerCase()}';
      expect(q1.options[q1.answerIndex].label.toLowerCase(), mix[key],
          reason: id);

      final q2 = activity.questions[1];
      final result = (q2.cue! as ColorSwatchCue).name.toLowerCase();
      final pair = q2.options[q2.answerIndex].label
          .toLowerCase()
          .replaceAll(' ', '');
      expect(mix[pair], result, reason: id);
      expect(activity.minAge, 5, reason: id);
    }
  });

  test('rainbow questions ask about the band that is actually missing', () {
    final activity = colorActivities.singleWhere((a) => a.id == 'colors_12');
    for (final question in activity.questions) {
      final cue = question.cue! as RainbowCue;
      final correct = question.options[question.answerIndex];
      expect(correct.color, cue.bands[cue.missingIndex],
          reason: question.prompt);
    }
    expect(activity.questions[0].spokenText, contains('first'));
    expect(activity.questions[1].spokenText, contains('after yellow'));
    expect(activity.questions[2].spokenText, contains('between red and yellow'));
  });

  testWidgets('every Colors cue type renders without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final seen = <Type>{};
    for (final question in questions) {
      final cue = question.cue!;
      if (!seen.add(cue.runtimeType)) continue;
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
      expect(tester.takeException(), isNull, reason: '${cue.runtimeType}');
    }
    expect(seen, containsAll(<Type>[
      ColorWordCue,
      ColorSwatchCue,
      ColorMixCue,
      RainbowCue,
      EmojiCue,
    ]));
  });

  testWidgets('color word cue stays on one line and mix cue shows symbols',
      (tester) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpQuestion(QuizQuestion question) => tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 260,
                  height: 160,
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

    final orange = colorActivities
        .singleWhere((activity) => activity.id == 'colors_05')
        .questions
        .first;
    await pumpQuestion(orange);
    await tester.pump();
    final word = find.text('ORANGE');
    expect(word, findsOneWidget);
    final paragraph = tester.renderObject<RenderParagraph>(word);
    expect(
      paragraph.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 6),
      ),
      hasLength(1),
    );

    final mixQuestion = colorActivities
        .singleWhere((activity) => activity.id == 'colors_09')
        .questions
        .first;
    await pumpQuestion(mixQuestion);
    await tester.pump();
    expect(find.text('+'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(find.text('?'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

bool _containsPhrase(String text, String phrase) {
  final escaped = RegExp.escape(phrase.toLowerCase());
  return RegExp(
    '(?<![a-z0-9])$escaped(?![a-z0-9])',
    caseSensitive: false,
  ).hasMatch(text);
}

bool _isEmoji(int rune) =>
    (rune >= 0x1F000 && rune <= 0x1FAFF) || (rune >= 0x2600 && rune <= 0x27BF);

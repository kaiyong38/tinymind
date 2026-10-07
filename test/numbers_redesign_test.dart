import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/tts_text_helper.dart';
import 'package:tinymind/widgets/emoji_glyph.dart';
import 'package:tinymind/widgets/question_cue_card.dart';

void main() {
  final numberActivities = worldCatalogs['numbers']!.activities;
  final allQuestions =
      numberActivities.expand((activity) => activity.questions).toList();

  test('Numbers ids, cues, play types, text and answers remain valid', () {
    expect(
      numberActivities.map((activity) => activity.id).toList(),
      List.generate(
          20, (index) => 'numbers_${(index + 1).toString().padLeft(2, '0')}'),
    );

    for (final activity in numberActivities) {
      expect(activity.questions, hasLength(3), reason: activity.id);
      expect(
        activity.questions.map((question) => question.playType).toSet(),
        hasLength(3),
        reason: activity.id,
      );
      final tuples = <String>{};
      for (final question in activity.questions) {
        expect(question.cue, isNotNull, reason: activity.id);
        expect(question.spokenText, isNotEmpty, reason: activity.id);
        expect(question.options, hasLength(3), reason: activity.id);
        expect(
          question.answerIndex,
          inInclusiveRange(0, question.options.length - 1),
          reason: activity.id,
        );
        expect(
          TtsTextHelper.clean(question.spokenText!).runes.any(_isEmoji),
          isFalse,
          reason: '${activity.id}: ${question.spokenText}',
        );
        expect(_wordCount(question.prompt), lessThanOrEqualTo(3),
            reason: '${activity.id}: ${question.prompt}');
        expect(_wordCount(question.hint ?? ''), lessThanOrEqualTo(6),
            reason: '${activity.id}: ${question.hint}');

        final correct = question.options[question.answerIndex];
        expect(int.tryParse(correct.label), isNotNull, reason: activity.id);
        final tuple = [
          question.prompt,
          question.cue!.identityKey,
          correct.identityKeyFor(question.visual),
        ].join('|');
        expect(tuples.add(tuple), isTrue, reason: '${activity.id}: $tuple');
        final numbers = question.options.map((option) {
          final number = int.parse(option.label);
          expect(number, greaterThanOrEqualTo(0), reason: activity.id);
          expect(
              (number - int.parse(correct.label)).abs(), inInclusiveRange(0, 2),
              reason: '${activity.id}: ${question.options}');
          return number;
        }).toList();
        expect(numbers.toSet(), hasLength(3), reason: activity.id);
      }

      final first = activity.questions.first;
      expect(first.teach, isNotNull, reason: activity.id);
      expect(first.teachOption, isNotNull, reason: activity.id);
      expect(_wordCount(first.teach!), lessThanOrEqualTo(8),
          reason: '${activity.id}: ${first.teach}');
      expect(first.teach, isNot(first.spokenText), reason: activity.id);
      expect(
        first.teachOption!.label,
        first.options[first.answerIndex].label,
        reason: activity.id,
      );
    }
  });

  test('prompts and speech do not reveal the correct number', () {
    for (final question in allQuestions) {
      final answer = int.parse(question.options[question.answerIndex].label);
      final number = answer.toString();
      final word = _numberWord(answer);
      expect(question.prompt, isNot(contains(number)),
          reason: '${question.prompt} reveals $number');
      expect(question.spokenText, isNot(contains(number)),
          reason: '${question.spokenText} reveals $number');
      expect(_containsWord(question.prompt.toLowerCase(), word), isFalse,
          reason: '${question.prompt} reveals $word');
      expect(
        _containsWord(question.spokenText!.toLowerCase(), word),
        isFalse,
        reason: '${question.spokenText} reveals $word',
      );
    }
  });

  test('answer indices are unchanged from the existing Numbers bank', () {
    const expected = [
      [0, 1, 2],
      [1, 2, 0],
      [2, 0, 1],
      [0, 1, 2],
      [1, 2, 0],
      [2, 0, 1],
      [0, 1, 2],
      [1, 2, 0],
      [2, 0, 1],
      [0, 1, 2],
      [1, 2, 0],
      [2, 0, 1],
      [0, 1, 2],
      [1, 2, 0],
      [2, 0, 1],
      [0, 1, 2],
      [1, 2, 0],
      [2, 0, 1],
      [0, 1, 2],
      [1, 2, 0],
    ];
    for (var index = 0; index < numberActivities.length; index++) {
      expect(
        numberActivities[index]
            .questions
            .map((question) => question.answerIndex)
            .toList(),
        expected[index],
        reason: numberActivities[index].id,
      );
    }
  });

  test('counting, addition, subtraction and ten-frame answers are correct', () {
    for (var index = 0; index < 10; index++) {
      final activity = numberActivities[index];
      for (final question in activity.questions) {
        final cue = question.cue! as ItemCountCue;
        final answer = int.parse(question.options[question.answerIndex].label);
        expect(cue.count, answer, reason: '${activity.id}: ${question.prompt}');
        if (question.visual == AnswerVisual.numberDots) {
          expect(question.options[question.answerIndex].count, answer,
              reason: activity.id);
        }
      }
    }

    for (var index = 10; index < 13; index++) {
      for (final question in numberActivities[index].questions) {
        final cue = question.cue! as EquationPictureCue;
        expect(
          cue.firstCount + cue.secondCount,
          int.parse(question.options[question.answerIndex].label),
          reason: numberActivities[index].id,
        );
      }
    }

    for (var index = 13; index < 15; index++) {
      for (final question in numberActivities[index].questions) {
        final cue = question.cue! as ItemCountCue;
        expect(
          cue.count - cue.removedCount,
          int.parse(question.options[question.answerIndex].label),
          reason: numberActivities[index].id,
        );
      }
    }

    for (final question in numberActivities[15].questions) {
      final cue = question.cue! as TenFrameCue;
      expect(cue.firstCount + cue.secondCount,
          int.parse(question.options[question.answerIndex].label));
    }
    for (final question in numberActivities[16].questions) {
      final cue = question.cue! as TenFrameCue;
      expect(cue.firstCount + cue.secondCount,
          int.parse(question.options[question.answerIndex].label));
    }
    for (final question in numberActivities[17].questions) {
      final cue = question.cue! as TenFrameCue;
      expect(cue.firstCount - cue.secondCount,
          int.parse(question.options[question.answerIndex].label));
    }
    for (final question in numberActivities[18].questions) {
      final cue = question.cue! as TenFrameCue;
      expect(10 - cue.firstCount,
          int.parse(question.options[question.answerIndex].label));
    }
    for (final question in numberActivities[19].questions) {
      final cue = question.cue! as TenFrameCue;
      expect(10 + cue.secondCount,
          int.parse(question.options[question.answerIndex].label));
    }
  });

  test('only the three specified counting cues are scattered', () {
    final scattered = <String, int>{};
    for (final activity in numberActivities) {
      for (final question in activity.questions) {
        final cue = question.cue;
        if (cue is ItemCountCue &&
            cue.arrangement == ItemCountArrangement.scattered) {
          scattered[activity.id] = cue.count;
        }
      }
    }
    expect(scattered, {'numbers_06': 7, 'numbers_08': 6, 'numbers_10': 8});
    expect(
      (numberActivities[6].questions[1].cue! as ItemCountCue).rows,
      3,
    );
    expect(
      (numberActivities[8].questions[1].cue! as ItemCountCue).rows,
      2,
    );
  });

  test('spoken subtraction and make-ten clues give operands, not answers', () {
    for (final id in ['numbers_14', 'numbers_15', 'numbers_18']) {
      final activity = numberActivities.singleWhere((item) => item.id == id);
      for (final question in activity.questions) {
        final spoken = question.spokenText!.toLowerCase();
        final cue = question.cue!;
        final first = switch (cue) {
          ItemCountCue() => cue.count,
          TenFrameCue() => cue.firstCount,
          _ => throw StateError('Unexpected subtraction cue: $cue'),
        };
        final removed = switch (cue) {
          ItemCountCue() => cue.removedCount,
          TenFrameCue() => cue.secondCount,
          _ => throw StateError('Unexpected subtraction cue: $cue'),
        };
        expect(_containsWord(spoken, _numberWord(first)), isTrue,
            reason: '$id: $spoken');
        expect(_containsWord(spoken, _numberWord(removed)), isTrue,
            reason: '$id: $spoken');
        final answer = int.parse(question.options[question.answerIndex].label);
        expect(_containsWord(spoken, _numberWord(answer)), isFalse,
            reason: '$id reveals ${_numberWord(answer)}');
      }
    }

    for (final question in numberActivities[18].questions) {
      final cue = question.cue! as TenFrameCue;
      final spoken = question.spokenText!.toLowerCase();
      expect(_containsWord(spoken, _numberWord(cue.firstCount)), isTrue);
      final answer = int.parse(question.options[question.answerIndex].label);
      expect(_containsWord(spoken, _numberWord(answer)), isFalse,
          reason: '$spoken reveals ${_numberWord(answer)}');
      expect(spoken, isNot(contains('space')));
      expect(spoken, isNot(contains('ten-frame')));
    }
  });

  testWidgets('new Numbers cues render without overflow at target sizes/scales',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cuesByIdentity = <String, QuizQuestion>{};
    for (final question in allQuestions) {
      if (question.cue is ItemCountCue ||
          question.cue is EquationPictureCue ||
          question.cue is TenFrameCue) {
        cuesByIdentity.putIfAbsent(question.cue!.identityKey, () => question);
      }
    }

    for (final question in cuesByIdentity.values) {
      for (final size in [const Size(568, 320), const Size(640, 360)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        for (final scale in [1.0, 1.3]) {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: MaterialApp(
                home: Scaffold(
                  body: QuestionCueCard(
                    question: question,
                    worldColor: Colors.orange,
                    onReplay: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${question.cue!.identityKey}, $size, text scale $scale',
          );
        }
      }
    }
  });

  testWidgets('scattered item rectangles remain separated and in the cue',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(568, 320), const Size(640, 360)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      for (final activity in numberActivities.where(
        (activity) =>
            ['numbers_06', 'numbers_08', 'numbers_10'].contains(activity.id),
      )) {
        final question = activity.questions[1];
        final cue = question.cue! as ItemCountCue;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuestionCueCard(
                question: question,
                worldColor: Colors.orange,
                onReplay: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final cueArea = find.byKey(
          ValueKey('item-count-cue-${cue.identityKey}'),
        );
        final areaRect = tester.getRect(cueArea);
        final glyphs = find.descendant(
          of: cueArea,
          matching: find.byType(EmojiGlyph),
        );
        expect(glyphs, findsNWidgets(cue.count), reason: activity.id);
        final itemRects = glyphs
            .evaluate()
            .map((element) => tester.getRect(find.byWidget(element.widget)))
            .toList();
        for (final rect in itemRects) {
          expect(rect.width, greaterThanOrEqualTo(28), reason: activity.id);
          expect(_containsRect(areaRect, rect), isTrue, reason: activity.id);
        }
        for (var first = 0; first < itemRects.length; first++) {
          for (var second = first + 1; second < itemRects.length; second++) {
            final distance =
                (itemRects[first].center - itemRects[second].center).distance;
            expect(
              distance,
              greaterThanOrEqualTo(itemRects[first].width * 1.15),
              reason:
                  '${activity.id}: ${itemRects[first]}, ${itemRects[second]}',
            );
          }
        }
        expect(tester.takeException(), isNull, reason: activity.id);
      }
    }
  });
}

int _wordCount(String text) => text
    .trim()
    .split(RegExp(r'\s+'))
    .where((word) => RegExp(r'[A-Za-z]').hasMatch(word))
    .length;

bool _containsWord(String text, String word) =>
    RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(text.toLowerCase());

String _numberWord(int value) => const {
      0: 'zero',
      1: 'one',
      2: 'two',
      3: 'three',
      4: 'four',
      5: 'five',
      6: 'six',
      7: 'seven',
      8: 'eight',
      9: 'nine',
      10: 'ten',
      11: 'eleven',
      12: 'twelve',
      13: 'thirteen',
      14: 'fourteen',
      15: 'fifteen',
      16: 'sixteen',
      17: 'seventeen',
      18: 'eighteen',
      19: 'nineteen',
      20: 'twenty',
    }[value]!;

bool _isEmoji(int rune) =>
    (rune >= 0x1F000 && rune <= 0x1FAFF) ||
    (rune >= 0x2600 && rune <= 0x27BF) ||
    (rune >= 0xFE00 && rune <= 0xFE0F);

bool _containsRect(Rect parent, Rect child) =>
    parent.left <= child.left &&
    parent.top <= child.top &&
    parent.right >= child.right &&
    parent.bottom >= child.bottom;

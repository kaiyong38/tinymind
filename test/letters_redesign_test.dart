import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/tts_text_helper.dart';
import 'package:tinymind/widgets/emoji_glyph.dart';
import 'package:tinymind/widgets/quiz_visuals.dart';

void main() {
  final activities = worldCatalogs['letters']!.activities;
  final questions = activities.expand((activity) => activity.questions);

  test('Letters ids, question metadata, text and answer positions are stable',
      () {
    expect(
      activities.map((activity) => activity.id).toList(),
      List.generate(
          26, (index) => 'letters_${String.fromCharCode(97 + index)}'),
    );
    const answerIndices = [
      [0, 1, 2],
      [1, 2, 0],
      [2, 0, 1],
    ];

    for (var activityIndex = 0;
        activityIndex < activities.length;
        activityIndex++) {
      final activity = activities[activityIndex];
      expect(activity.minAge, 3, reason: activity.id);
      expect(activity.questions, hasLength(3), reason: activity.id);
      final tuples = <String>{};
      for (var questionIndex = 0; questionIndex < 3; questionIndex++) {
        final question = activity.questions[questionIndex];
        expect(question.playType, PlayType.values[questionIndex],
            reason: '${activity.id} Q${questionIndex + 1}');
        expect(question.cue, isNotNull, reason: activity.id);
        expect(question.spokenText, isNotEmpty, reason: activity.id);
        expect(question.options, hasLength(3), reason: activity.id);
        expect(question.answerIndex,
            answerIndices[activityIndex % 3][questionIndex],
            reason: '${activity.id} Q${questionIndex + 1}');
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
        final tuple = [
          question.prompt,
          question.cue!.identityKey,
          correct.identityKeyFor(question.visual),
        ].join('|');
        expect(tuples.add(tuple), isTrue, reason: '${activity.id}: $tuple');

        if (questionIndex == 0) {
          expect(question.cue, isA<EmojiCue>(), reason: activity.id);
          expect(question.visual, AnswerVisual.letterPicture,
              reason: activity.id);
          expect(question.teach, isNotEmpty, reason: activity.id);
          expect(question.teachOption, isNotNull, reason: activity.id);
          expect(_wordCount(question.teach!), lessThanOrEqualTo(8),
              reason: '${activity.id}: ${question.teach}');
          expect(question.teach, isNot(question.spokenText),
              reason: activity.id);
          expect(question.teachOption!.label, activity.title,
              reason: activity.id);
          expect(question.teachOption!.emoji, (question.cue! as EmojiCue).emoji,
              reason: activity.id);
          expect(correct.emoji, (question.cue! as EmojiCue).emoji,
              reason: '${activity.id}: correct letter card image');
        } else {
          expect(question.teach, isNull, reason: activity.id);
          expect(question.teachOption, isNull, reason: activity.id);
        }

        if (questionIndex == 2) {
          expect(question.visual, AnswerVisual.picture, reason: activity.id);
          expect(question.cue, isA<LetterCue>(), reason: activity.id);
          expect(
            RegExp(
              '\\b${RegExp.escape(correct.label)}\\b',
              caseSensitive: false,
            ).hasMatch(question.prompt),
            isFalse,
            reason: '${activity.id}: prompt reveals ${correct.label}',
          );
          expect(
            RegExp(
              '\\b${RegExp.escape(correct.label)}\\b',
              caseSensitive: false,
            ).hasMatch(question.spokenText!),
            isFalse,
            reason: '${activity.id}: speech reveals ${correct.label}',
          );
        }
      }
    }
  });

  test('Q2 pairs opposite cases and avoids target letter shape groups', () {
    const shapeGroups = [
      {'a', 'c', 'e', 'o', 'g', 'q'},
      {'b', 'd', 'p', 'q'},
      {'m', 'n', 'r', 'h', 'u'},
      {'i', 'j', 'l', 't', 'f'},
      {'v', 'w', 'y'},
      {'k', 'x', 'z'},
    ];
    const specifiedDistractors = {
      'letters_a': ['t', 'w'],
      'letters_f': ['o', 'm'],
      'letters_g': ['t', 'k'],
      'letters_h': ['l', 't'],
      'letters_m': ['t', 'k'],
      'letters_o': ['t', 'k'],
      'letters_q': ['t', 'w'],
    };

    for (var index = 0; index < activities.length; index++) {
      final activity = activities[index];
      final question = activity.questions[1];
      final cue = question.cue! as LetterCue;
      final target = activity.title.toLowerCase();
      final isCapitalCue = index.isEven;
      expect(cue.text, isCapitalCue ? target.toUpperCase() : target,
          reason: activity.id);
      final correct = question.options[question.answerIndex].label;
      expect(correct, isCapitalCue ? target : target.toUpperCase(),
          reason: activity.id);

      final distractors = [
        for (var optionIndex = 0;
            optionIndex < question.options.length;
            optionIndex++)
          if (optionIndex != question.answerIndex)
            question.options[optionIndex].label.toLowerCase(),
      ];
      for (final distractor in distractors) {
        expect(distractor, isNot(target), reason: activity.id);
        for (final group
            in shapeGroups.where((group) => group.contains(target))) {
          expect(group.contains(distractor), isFalse,
              reason: '${activity.id}: $target and $distractor share $group');
        }
      }

      final expected = specifiedDistractors[activity.id];
      if (expected != null) {
        expect(distractors.toSet(), expected.toSet(), reason: activity.id);
      }
    }
  });

  test('Q3 pictures are unique, clear, and match their spoken names', () {
    final q1Pictures = {
      for (final activity in activities)
        (activity.questions.first.cue! as EmojiCue).emoji,
    };
    final q3Pictures = <String>{};

    for (final activity in activities) {
      final question = activity.questions[2];
      final cue = question.cue! as LetterCue;
      final letter = activity.title.toLowerCase();
      final isX = letter == 'x';
      expect(cue.text, isX ? 'Xx' : '${letter.toUpperCase()}$letter',
          reason: activity.id);
      expect(question.prompt,
          isX ? 'Ends with X?' : 'Starts with ${letter.toUpperCase()}?',
          reason: activity.id);

      final correct = question.options[question.answerIndex];
      final correctWord = correct.label.toLowerCase();
      expect(
        isX ? correctWord.endsWith('x') : correctWord.startsWith(letter),
        isTrue,
        reason: '${activity.id}: ${correct.label}',
      );
      for (var optionIndex = 0;
          optionIndex < question.options.length;
          optionIndex++) {
        final option = question.options[optionIndex];
        expect(option.emoji, isNotNull,
            reason: '${activity.id}: ${option.label}');
        expect(q3Pictures.add(option.emoji!), isTrue,
            reason: 'Repeated Q3 picture: ${option.emoji}');
        expect(q1Pictures.contains(option.emoji), isFalse,
            reason: 'Q3 picture reused a Q1 cue: ${option.emoji}');
        if (optionIndex != question.answerIndex) {
          expect(option.label.toLowerCase().startsWith(letter), isFalse,
              reason: '${activity.id}: distractor ${option.label}');
        }
      }

      final distractors = [
        for (var optionIndex = 0;
            optionIndex < question.options.length;
            optionIndex++)
          if (optionIndex != question.answerIndex)
            question.options[optionIndex],
      ];
      final allOptions = [correct, ...distractors];
      expect(
        allOptions.map((option) => option.label[0].toLowerCase()).toSet(),
        hasLength(3),
        reason: '${activity.id}: repeated initial letter',
      );
      for (var first = 0; first < allOptions.length; first++) {
        for (var second = first + 1; second < allOptions.length; second++) {
          expect(
            _hasConfusableInitialSounds(
              allOptions[first].label,
              allOptions[second].label,
            ),
            isFalse,
            reason:
                '${activity.id}: ${allOptions[first].label} / ${allOptions[second].label}',
          );
        }
      }

      if ('aeiou'.contains(letter)) {
        for (final distractor in distractors) {
          expect(
            'aeiou'.contains(distractor.label[0].toLowerCase()),
            isFalse,
            reason: '${activity.id}: vowel distractor ${distractor.label}',
          );
        }
      }
    }
    expect(q3Pictures, hasLength(78));
    expect(
      activities
          .expand((activity) => activity.questions[2].options)
          .where((option) => option.label == 'Shoe')
          .single
          .emoji,
      '👟',
    );
    expect(
      activities
          .expand((activity) => activity.questions[2].options)
          .where((option) => option.label == 'Broom')
          .single
          .emoji,
      '🧹',
    );
    expect(
      activities
          .expand((activity) => activity.questions[2].options)
          .where((option) => option.label == 'Bulb')
          .single
          .emoji,
      '💡',
    );
  });

  test('Letters question bank uses no emoji newer than Unicode 12', () {
    const unicode12EmojiInExtendedRange = {0x1FA80, 0x1FA81};
    final strings = <String>[
      ...worldCatalogs['letters']!.sections.map((section) => section.emoji),
      ...activities.map((activity) => activity.emoji),
      for (final question in questions) ...[
        question.prompt,
        question.teach ?? '',
        question.spokenText ?? '',
        question.hint ?? '',
        for (final option in question.options) ...[
          option.label,
          option.emoji ?? '',
        ],
        if (question.teachOption != null) ...[
          question.teachOption!.label,
          question.teachOption!.emoji ?? '',
        ],
        if (question.cue is EmojiCue) (question.cue! as EmojiCue).emoji,
        if (question.cue is LetterCue) (question.cue! as LetterCue).text,
      ],
    ];

    for (final text in strings) {
      for (final rune in text.runes) {
        expect(rune, isNot(inInclusiveRange(0x1F9AB, 0x1F9AD)),
            reason: 'Unicode 13 emoji in "$text"');
        expect(rune, isNot(0x1F9CB), reason: 'Unicode 13 emoji in "$text"');
        if (rune >= 0x1FA70 && rune <= 0x1FAFF) {
          expect(
            unicode12EmojiInExtendedRange.contains(rune),
            isTrue,
            reason: 'Emoji code point U+${rune.toRadixString(16)} in "$text"',
          );
        }
      }
    }
  });

  testWidgets('every Q3 option EmojiGlyph renders at 568x320', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(568, 320);

    for (final activity in activities) {
      for (final option in activity.questions[2].options) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => buildQuizVisual(
                    context,
                    option,
                    AnswerVisual.picture,
                    size: 160,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.byType(EmojiGlyph), findsOneWidget,
            reason: '${activity.id}: ${option.label}');
        expect(tester.takeException(), isNull,
            reason: '${activity.id}: ${option.label}');
      }
    }
  });
}

int _wordCount(String text) => text.trim().split(RegExp(r'\s+')).length;

bool _isEmoji(int rune) =>
    rune >= 0x1F000 && rune <= 0x1FAFF || rune >= 0x2600 && rune <= 0x27FF;

bool _hasConfusableInitialSounds(String first, String second) {
  final firstSound = _initialSound(first);
  final secondSound = _initialSound(second);
  const groups = [
    {'c', 'k', 's'},
    {'g', 'j'},
    {'j', 'ch'},
    {'q', 'k'},
    {'f', 'ph'},
  ];
  return groups.any(
    (group) => group.contains(firstSound) && group.contains(secondSound),
  );
}

String _initialSound(String word) {
  final lower = word.toLowerCase();
  if (lower.startsWith('cheese')) return 'ch';
  if (lower.startsWith('ph')) return 'ph';
  if (lower.startsWith('shell') ||
      lower.startsWith('sheep') ||
      lower.startsWith('shoe')) {
    return 'sh';
  }
  return switch (lower[0]) {
    'c' => 'c',
    'k' => 'k',
    's' => 's',
    'g' => 'g',
    'j' => 'j',
    'q' => 'q',
    _ => lower[0],
  };
}

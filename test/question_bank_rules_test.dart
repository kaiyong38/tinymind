import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/tts_text_helper.dart';

const _blockedPostUnicode12Emoji = {
  '🛝',
  '🩷',
  '🫶',
  '🪻',
  '🪆',
  '🪟',
};

final _interjections = RegExp(
  r'\b(?:ooh|oh|hmm|woo|yay|hooray|whoa|wow|uh-oh)\b',
  caseSensitive: false,
);

final _wordOrNumber = RegExp(r"[A-Za-z]+(?:['’][A-Za-z]+)*|\d+");

void main() {
  final allActivities = worldCatalogs.values
      .expand((catalog) => catalog.activities)
      .toList(growable: false);

  test('all question text meets the question-bank language rules', () {
    final failures = <String>[];

    for (final activity in allActivities) {
      for (var index = 0; index < activity.questions.length; index++) {
        final question = activity.questions[index];
        final label = '${activity.id} Q${index + 1}';
        final spokenText = question.spokenText;

        if (question.cue == null) failures.add('$label: missing cue');
        if (question.playType == null) failures.add('$label: missing playType');
        if (spokenText == null || spokenText.trim().isEmpty) {
          failures.add('$label: missing spokenText');
        } else if (_containsEmoji(TtsTextHelper.clean(spokenText))) {
          failures.add('$label: TTS text contains emoji');
        }

        final promptWordCount = _countWords(question.prompt);
        if (promptWordCount > 3) {
          failures.add('$label: prompt has $promptWordCount words');
        }

        final hintWordCount = _countWords(question.hint ?? '');
        if (hintWordCount > 6) {
          failures.add('$label: hint has $hintWordCount words');
        }

        final teachWordCount = _countWords(question.teach ?? '');
        if (teachWordCount > 8) {
          failures.add('$label: teach has $teachWordCount words');
        }
        if (index > 0 && question.teach != null) {
          failures.add('$label: teach is only allowed on Q1');
        }
        if (index == 0 &&
            question.teach != null &&
            spokenText != null &&
            _normalizedText(spokenText) == _normalizedText(question.teach!)) {
          failures.add('$label: spokenText repeats teach');
        }

        if (_hasInterjection(spokenText) ||
            _hasInterjection(question.teach) ||
            _hasInterjection(question.hint)) {
          failures.add('$label: contains an interjection');
        }

        if (spokenText == null ||
            question.playType == PlayType.lookListen ||
            question.playType == PlayType.findSame) {
          continue;
        }

        final correct = question.options[question.answerIndex];
        final correctPhrases = <String>{
          correct.label,
          if (correct.count != null) '${correct.count}',
          if (_integerValue(correct.label) case final number?)
            '$number',
          if (_integerValue(correct.label) case final number?)
            _numberWord(number),
        }.where((phrase) => phrase.trim().isNotEmpty);
        for (final text in [question.prompt, spokenText]) {
          for (final phrase in correctPhrases) {
            if (_containsPhrase(text, phrase)) {
              failures.add('$label: text names correct answer "$phrase"');
            }
          }
        }
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('target pictures and activity emojis are unique within each world',
      () {
    for (final entry in worldCatalogs.entries) {
      final ownerByEmoji = <String, String>{};
      final duplicates = <String>{};
      for (final activity in entry.value.activities) {
        final targetPictures = [
          if (activity.emoji != '➕' && activity.emoji != '➖') activity.emoji,
          for (final question in activity.questions)
            if (question.visual == AnswerVisual.picture ||
                question.visual == AnswerVisual.letterPicture)
              if (question.options[question.answerIndex].emoji case final emoji?)
                emoji,
        ];
        for (final emoji in targetPictures) {
          final normalized = _withoutVariationSelector(emoji);
          final previousOwner = ownerByEmoji[normalized];
          if (previousOwner != null && previousOwner != activity.id) {
            duplicates.add(
              '${entry.key}: $emoji used by $previousOwner and ${activity.id}',
            );
          } else {
            ownerByEmoji[normalized] = activity.id;
          }
        }
      }
      expect(duplicates, isEmpty, reason: duplicates.join('\n'));
    }
  });

  test('question bank excludes the known post-Unicode-12 emoji', () {
    final content = StringBuffer();
    for (final activity in allActivities) {
      content
        ..write(activity.emoji)
        ..write(activity.title);
      for (final question in activity.questions) {
        content
          ..write(question.prompt)
          ..write(question.hint ?? '')
          ..write(question.teach ?? '')
          ..write(question.spokenText ?? '')
          ..write(question.cue?.identityKey ?? '');
        for (final option in [
          ...question.options,
          if (question.teachOption != null) question.teachOption!,
        ]) {
          content
            ..write(option.label)
            ..write(option.emoji ?? '');
        }
      }
    }

    for (final blockedEmoji in _blockedPostUnicode12Emoji) {
      expect(content.toString(), isNot(contains(blockedEmoji)),
          reason: '$blockedEmoji is newer than Unicode 12');
    }
  });

  test('activity emojis do not reveal non-teaching correct picture answers',
      () {
    final failures = <String>[];
    for (final activity in allActivities) {
      final activityEmoji = _withoutVariationSelector(activity.emoji);
      for (var index = 0; index < activity.questions.length; index++) {
        final question = activity.questions[index];
        if (index == 0 || question.playType == PlayType.lookListen) continue;
        final answerEmoji =
            question.options[question.answerIndex].emoji;
        if (answerEmoji != null &&
            _withoutVariationSelector(answerEmoji) == activityEmoji) {
          failures.add('${activity.id} Q${index + 1}: $answerEmoji');
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

int _countWords(String text) => _wordOrNumber
    .allMatches(text)
    .where((match) => int.tryParse(match[0]!) == null)
    .length;

int? _integerValue(String text) => int.tryParse(text.trim());

String _numberWord(int number) => const {
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
    }[number] ??
    '$number';

bool _containsPhrase(String text, String phrase) {
  final escapedPhrase = RegExp.escape(phrase.trim());
  return RegExp(
    r'(?<![A-Za-z0-9])' + escapedPhrase + r'(?![A-Za-z0-9])',
    caseSensitive: false,
  ).hasMatch(text);
}

bool _containsEmoji(String text) =>
    text.runes.any((rune) => (rune >= 0x1F000 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0x2B00 && rune <= 0x2BFF) ||
        (rune >= 0x2300 && rune <= 0x23FF));

bool _hasInterjection(String? text) =>
    text != null && _interjections.hasMatch(text);

String _normalizedText(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _withoutVariationSelector(String text) =>
    text.replaceAll('\uFE0F', '');

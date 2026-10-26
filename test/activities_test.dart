import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';

void main() {
  test('every world has sections and activities', () {
    expect(
        worldCatalogs.keys.toSet(), {'letters', 'numbers', 'shapes', 'colors'});
    for (final entry in worldCatalogs.entries) {
      expect(entry.value.sections, isNotEmpty, reason: entry.key);
      expect(entry.value.activities, isNotEmpty, reason: entry.key);
      expect(
          entry.value.youngMaxSection, lessThan(entry.value.sections.length));
    }
  });

  test('activity counts per world', () {
    expect(worldCatalogs['letters']!.activities.length, 26);
    expect(worldCatalogs['numbers']!.activities.length, 20);
    expect(worldCatalogs['shapes']!.activities.length, 12);
    expect(worldCatalogs['colors']!.activities.length, 12);
  });

  test('activity ids match the stable ordered snapshot', () {
    final expectedIds = [
      ...'abcdefghijklmnopqrstuvwxyz'
          .split('')
          .map((letter) => 'letters_$letter'),
      for (var number = 1; number <= 20; number++)
        'numbers_${number.toString().padLeft(2, '0')}',
      for (var number = 1; number <= 12; number++)
        'shapes_${number.toString().padLeft(2, '0')}',
      for (var number = 1; number <= 12; number++)
        'colors_${number.toString().padLeft(2, '0')}',
    ];
    expect(
      worldCatalogs.values
          .expand((catalog) => catalog.activities)
          .map((activity) => activity.id)
          .toList(),
      expectedIds,
    );
  });

  test('ids are unique and every activity has 3 valid questions', () {
    final ids = <String>{};
    for (final catalog in worldCatalogs.values) {
      for (final a in catalog.activities) {
        expect(ids.add(a.id), isTrue, reason: 'duplicate id ${a.id}');
        expect(a.sectionIndex, lessThan(catalog.sections.length));
        expect(a.minAge, greaterThanOrEqualTo(3), reason: a.id);
        expect(a.questions.length, 3, reason: a.id);
        for (final q in a.questions) {
          expect(q.options.length, 3, reason: a.id);
          expect(q.answerIndex, inInclusiveRange(0, 2), reason: a.id);
          final labels = q.options.map((o) => o.label).toSet();
          expect(labels.length, 3, reason: 'duplicate option in ${a.id}');
        }
        // Only the first question teaches before testing.
        expect(a.questions[1].teach, isNull, reason: a.id);
        expect(a.questions[2].teach, isNull, reason: a.id);
      }
    }
  });

  test('activity emojis do not reveal non-teaching correct picture answers',
      () {
    final activities =
        worldCatalogs.values.expand((catalog) => catalog.activities).toList();
    expect(activities, hasLength(70));

    for (final activity in activities) {
      for (final question in activity.questions) {
        if (question.playType == PlayType.lookListen) continue;

        final answerEmoji = question.options[question.answerIndex].emoji;
        if (answerEmoji == null) continue;

        expect(
          _withoutEmojiVariationSelector(answerEmoji),
          isNot(_withoutEmojiVariationSelector(activity.emoji)),
          reason: '${activity.id}: activity emoji reveals a correct answer',
        );
      }
    }
  });

  test(
      'replacement activity emojis are supported and absent from later options',
      () {
    const expectedEmojiByActivityId = {
      'letters_x': '📦',
      'shapes_04': '🌠',
      'shapes_06': '🟦',
      'shapes_07': '🔺',
      'shapes_08': '✨',
    };
    const introducedUnicodeVersionByEmoji = {
      '📦': 6,
      '🌠': 6,
      '🟦': 12,
      '🔺': 6,
      '✨': 6,
    };

    for (final entry in expectedEmojiByActivityId.entries) {
      final activity = activityById(entry.key)!;
      expect(activity.emoji, entry.value, reason: entry.key);
      expect(
        introducedUnicodeVersionByEmoji[entry.value],
        lessThanOrEqualTo(12),
        reason: '${entry.key}: ${entry.value}',
      );

      final activityEmoji = _withoutEmojiVariationSelector(activity.emoji);
      for (final question in activity.questions) {
        if (question.playType == PlayType.lookListen) continue;
        for (final option in question.options) {
          final optionEmoji = option.emoji;
          if (optionEmoji == null) continue;
          expect(
            _withoutEmojiVariationSelector(optionEmoji),
            isNot(activityEmoji),
            reason: '${entry.key}: activity emoji is also an option picture',
          );
        }
      }
    }
  });

  test('starsForScore', () {
    expect(starsForScore(3, 3), 3);
    expect(starsForScore(2, 3), 2);
    expect(starsForScore(1, 3), 1);
    expect(starsForScore(0, 3), 1);
  });

  test('worldFinished needs 3 stars on every age-suitable activity', () {
    expect(worldFinished(worldId: 'numbers', age: 4, bestStars: {}), isFalse);
    final allEarlierNumbersHaveThreeStars = {
      for (var number = 1; number <= 15; number++)
        'numbers_${number.toString().padLeft(2, '0')}': 3,
    };
    expect(
      worldFinished(
        worldId: 'numbers',
        age: 3,
        bestStars: allEarlierNumbersHaveThreeStars,
      ),
      isTrue,
    );
    expect(
      worldFinished(
        worldId: 'numbers',
        age: 6,
        bestStars: allEarlierNumbersHaveThreeStars,
      ),
      isFalse,
    );
  });

  test('abstract activities require age 5 and remain available to older kids',
      () {
    const ageFiveActivityIds = {
      'numbers_19',
      'shapes_09',
      'shapes_10',
      'shapes_12',
      'colors_09',
      'colors_10',
      'colors_11',
      'colors_12',
    };
    for (final id in ageFiveActivityIds) {
      expect(activityById(id)?.minAge, 5, reason: id);
      expect(activityById(id), isNotNull, reason: 'Keep $id manually playable');
    }

    final allEarlierColorsHaveThreeStars = {
      for (final activity in worldCatalogs['colors']!.activities)
        if (activity.id != 'colors_09' &&
            activity.id != 'colors_10' &&
            activity.id != 'colors_11' &&
            activity.id != 'colors_12')
          activity.id: 3,
    };
    expect(
      worldFinished(
        worldId: 'colors',
        age: 5,
        bestStars: allEarlierColorsHaveThreeStars,
      ),
      isFalse,
    );
    expect(
      worldFinished(
        worldId: 'colors',
        age: 4,
        bestStars: allEarlierColorsHaveThreeStars,
      ),
      isTrue,
    );
  });
  group('nextActivityId', () {
    test('follows the order of the world, even for finished activities', () {
      expect(
        nextActivityId(worldId: 'colors', age: 5, currentId: 'colors_01'),
        'colors_02',
      );
      expect(
        nextActivityId(worldId: 'shapes', age: 4, currentId: 'shapes_01'),
        'shapes_02',
      );
    });

    test('skips activities that are too advanced for the child', () {
      // colors_09 to colors_12 are for ages 5 and up.
      expect(
        nextActivityId(worldId: 'colors', age: 3, currentId: 'colors_08'),
        isNull,
      );
      expect(
        nextActivityId(worldId: 'colors', age: 5, currentId: 'colors_08'),
        'colors_09',
      );
    });

    test('returns null for the last activity or an unknown id', () {
      expect(
        nextActivityId(worldId: 'colors', age: 6, currentId: 'colors_12'),
        isNull,
      );
      expect(
        nextActivityId(worldId: 'colors', age: 6, currentId: 'nope'),
        isNull,
      );
    });
  });
}

String _withoutEmojiVariationSelector(String emoji) =>
    emoji.replaceAll('\uFE0F', '');

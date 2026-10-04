import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/models/activities.dart';

void main() {
  test('every world has sections and activities', () {
    expect(
        worldCatalogs.keys.toSet(), {'letters', 'numbers', 'shapes', 'colors'});
    for (final entry in worldCatalogs.entries) {
      expect(entry.value.sections, isNotEmpty, reason: entry.key);
      expect(entry.value.activities, isNotEmpty, reason: entry.key);
      expect(
          entry.value.olderStartSection, lessThan(entry.value.sections.length));
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

  test('starsForScore', () {
    expect(starsForScore(3, 3), 3);
    expect(starsForScore(2, 3), 2);
    expect(starsForScore(1, 3), 1);
    expect(starsForScore(0, 3), 1);
  });

  test('recommendedActivityId follows age and stars', () {
    expect(recommendedActivityId(worldId: 'numbers', age: 4, bestStars: {}),
        'numbers_01');
    expect(recommendedActivityId(worldId: 'numbers', age: 6, bestStars: {}),
        'numbers_11');
    expect(
        recommendedActivityId(
            worldId: 'numbers', age: 4, bestStars: {'numbers_01': 3}),
        'numbers_02');
    expect(
        recommendedActivityId(
            worldId: 'numbers', age: 4, bestStars: {'numbers_01': 1}),
        'numbers_01');
  });

  test('3-year-olds are not recommended numbers beyond section 2', () {
    final allEarlierNumbersHaveThreeStars = {
      for (var number = 1; number <= 15; number++)
        'numbers_${number.toString().padLeft(2, '0')}': 3,
    };

    expect(
      recommendedActivityId(
        worldId: 'numbers',
        age: 3,
        bestStars: allEarlierNumbersHaveThreeStars,
      ),
      isNull,
    );
  });

  test('6-year-olds can be recommended numbers from section 3', () {
    final starsBeforeSectionThree = {
      for (var number = 1; number <= 15; number++)
        'numbers_${number.toString().padLeft(2, '0')}': 3,
    };

    expect(
      recommendedActivityId(
        worldId: 'numbers',
        age: 6,
        bestStars: starsBeforeSectionThree,
      ),
      'numbers_16',
    );
  });

  test('4-year-olds finish colors recommendations at the young section cap',
      () {
    final allowedColorActivities = {
      for (final activity in worldCatalogs['colors']!.activities)
        if (activity.sectionIndex <= 1) activity.id: 3,
    };

    expect(
      recommendedActivityId(
        worldId: 'colors',
        age: 4,
        bestStars: allowedColorActivities,
      ),
      isNull,
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
      recommendedActivityId(
        worldId: 'colors',
        age: 5,
        bestStars: allEarlierColorsHaveThreeStars,
      ),
      'colors_09',
    );
  });
}

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/firestore_service.dart';
import 'package:tinymind/services/progress_store.dart';

void main() {
  test('activity stars serialize and old progress data remains readable', () {
    final oldProgress = UserProgress.fromJson({
      'points': 12,
      'streak': 30,
      'difficultyScoreByModule': {'letters': 72.0},
    });
    expect(oldProgress.activityStars, isEmpty);
    expect(oldProgress.streak, 0);
    expect(
        oldProgress.toJson().containsKey('difficultyScoreByModule'), isFalse);

    final progress = UserProgress(activityStars: {'letters_a': 3});
    final restored = UserProgress.fromJson(progress.toJson());
    expect(restored.activityStars, {'letters_a': 3});
  });

  test('streak is the consecutive run ending today or yesterday', () {
    final today = DateTime.now();
    String keyFor(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final todayKey = keyFor(today);
    final yesterdayKey = keyFor(today.subtract(const Duration(days: 1)));
    final twoDaysAgoKey = keyFor(today.subtract(const Duration(days: 2)));

    expect(
      UserProgress(dailyStats: {
        todayKey: [1, 1],
        yesterdayKey: [3, 2],
      }).streak,
      2,
    );
    expect(
      UserProgress(dailyStats: {
        yesterdayKey: [1, 0],
      }).streak,
      1,
    );
    expect(
      UserProgress(dailyStats: {
        twoDaysAgoKey: [1, 1],
      }).streak,
      0,
    );
  });

  test('daysLearned counts distinct recorded days, even when not consecutive',
      () {
    final progress = UserProgress(dailyStats: {
      '2026-01-01': [2, 1],
      '2026-01-04': [5, 3],
      '2026-02-12': [1, 1],
    });
    final sameDayMultipleAnswers = UserProgress(dailyStats: {
      '2026-03-08': [8, 6],
    });

    expect(progress.daysLearned, 3);
    expect(sameDayMultipleAnswers.daysLearned, 1);
    expect(progress.toJson()['daysLearned'], 3);
  });

  test('recordActivityResult only replaces a best score with more stars',
      () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProgressStore();

    await store.recordActivityResult('letters_a', 2);
    await store.recordActivityResult('letters_a', 1);
    expect(store.progress.activityStars['letters_a'], 2);

    await store.recordActivityResult('letters_a', 3);
    expect(store.progress.activityStars['letters_a'], 3);

    final preferences = await SharedPreferences.getInstance();
    final cached = jsonDecode(preferences.getString('tinymind_progress')!)
        as Map<String, dynamic>;
    expect(cached['activityStars'], {'letters_a': 3});
  });

  test('older and newer progress writes preserve stars, ids and play days',
      () {
    final older = {
      'points': 10,
      'totalQuestions': 2,
      'activityStars': {'letters_a': 1},
      'completedQuestionIds': ['letters_a_1'],
      'dailyStats': {
        '2026-10-11': [2, 1],
      },
      'lastPlayed': '2026-10-11T10:00:00.000',
    };
    final newer = {
      'points': 30,
      'totalQuestions': 4,
      'activityStars': {'letters_a': 3, 'numbers_01': 2},
      'completedQuestionIds': ['letters_a_2'],
      'dailyStats': {
        '2026-10-12': [2, 2],
      },
      'lastPlayed': '2026-10-12T10:00:00.000',
    };

    final oldThenNew = FirestoreService.mergeProgressData(older, newer);
    final newThenOld = FirestoreService.mergeProgressData(newer, older);

    for (final merged in [oldThenNew, newThenOld]) {
      expect(merged['points'], 30);
      expect(merged['totalQuestions'], 4);
      expect(merged['activityStars'], {
        'letters_a': 3,
        'numbers_01': 2,
      });
      expect(
        merged['completedQuestionIds'],
        containsAll(['letters_a_1', 'letters_a_2']),
      );
      expect(
        (merged['dailyStats'] as Map).keys,
        containsAll(['2026-10-11', '2026-10-12']),
      );
      expect(merged['lastPlayed'], '2026-10-12T10:00:00.000');
    }
  });
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/pages/achievement_page.dart';
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

  group('daily check-in streak', () {
    String keyFor(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    String daysAgo(int days) {
      final now = DateTime.now();
      return keyFor(DateTime(now.year, now.month, now.day - days));
    }

    test('counts three consecutive days ending today', () {
      final progress = UserProgress(dailyStats: {
        daysAgo(0): [1, 1],
        daysAgo(1): [2, 1],
        daysAgo(2): [3, 3],
      });
      expect(progress.streak, 3);
    });

    test('a missed day restarts the count after the gap', () {
      final progress = UserProgress(dailyStats: {
        daysAgo(0): [1, 1],
        daysAgo(1): [1, 1],
        // daysAgo(2) missed.
        daysAgo(3): [1, 1],
        daysAgo(4): [1, 1],
        daysAgo(5): [1, 1],
      });
      expect(progress.streak, 2);
      expect(progress.daysLearned, 5);
    });

    test('does not reset when today is not played yet but yesterday was', () {
      final progress = UserProgress(dailyStats: {
        daysAgo(1): [1, 1],
        daysAgo(2): [1, 1],
      });
      expect(progress.streak, 2);
    });

    test('is zero when nothing was played since the day before yesterday', () {
      final progress = UserProgress(dailyStats: {
        daysAgo(2): [1, 1],
        daysAgo(3): [1, 1],
      });
      expect(progress.streak, 0);
      expect(UserProgress().streak, 0);
    });

    test('bestStreak is the longest run in history', () {
      final progress = UserProgress(dailyStats: {
        '2026-03-06': [1, 1],
        '2026-03-01': [1, 1],
        '2026-03-03': [1, 1],
        '2026-03-05': [1, 1],
        '2026-03-02': [1, 1],
      });
      expect(progress.bestStreak, 3);
      expect(UserProgress().bestStreak, 0);
      expect(
        UserProgress(dailyStats: {
          '2026-03-09': [1, 1],
        }).bestStreak,
        1,
      );
    });

    test('bestStreak continues across month and year boundaries', () {
      expect(
        UserProgress(dailyStats: {
          '2026-01-30': [1, 1],
          '2026-01-31': [1, 1],
          '2026-02-01': [1, 1],
          '2026-02-02': [1, 1],
        }).bestStreak,
        4,
      );
      expect(
        UserProgress(dailyStats: {
          '2025-12-30': [1, 1],
          '2025-12-31': [1, 1],
          '2026-01-01': [1, 1],
        }).bestStreak,
        3,
      );
      expect(
        UserProgress(dailyStats: {
          '2028-02-28': [1, 1],
          '2028-02-29': [1, 1],
          '2028-03-01': [1, 1],
        }).bestStreak,
        3,
      );
    });

    test('streak counts back across a month boundary', () {
      final progress = UserProgress(dailyStats: {
        '2026-02-01': [1, 1],
        '2026-01-31': [1, 1],
        '2026-01-30': [1, 1],
      });
      expect(progress.streakOn(DateTime(2026, 2, 1)), 3);
      expect(progress.streakOn(DateTime(2026, 2, 2)), 3);
      expect(progress.streakOn(DateTime(2026, 2, 3)), 0);
    });

    testWidgets('Three-day explorer stays unlocked after the streak breaks',
        (tester) async {
      final progress = UserProgress(dailyStats: {
        '2026-01-01': [1, 1],
        '2026-01-02': [1, 1],
        '2026-01-03': [1, 1],
      });
      expect(progress.bestStreak, 3);
      expect(progress.streak, 0);

      final page = AchievementPage(progress: progress);
      final explorer = page.achievements.singleWhere(
          (achievement) => achievement.title == 'Three-day explorer');
      expect(explorer.unlocked, isTrue);
      expect(explorer.description, 'Play 3 days in a row');

      await tester.pumpWidget(MaterialApp(home: page));
      final card = find.ancestor(
        of: find.text('Three-day explorer'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: card, matching: find.byIcon(Icons.check_circle)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.byIcon(Icons.lock_outline)),
        findsNothing,
      );
    });

    testWidgets('Three-day explorer stays locked for 3 scattered days',
        (tester) async {
      final page = AchievementPage(
        progress: UserProgress(dailyStats: {
          '2026-01-01': [1, 1],
          '2026-01-03': [1, 1],
          '2026-01-05': [1, 1],
        }),
      );
      expect(
        page.achievements
            .singleWhere((a) => a.title == 'Three-day explorer')
            .unlocked,
        isFalse,
      );
    });
  });

  test('recordAnswer keeps only the most recent 366 play days', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProgressStore();
    final now = DateTime.now();
    String keyFor(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    // 400 consecutive days ending yesterday.
    for (var offset = 1; offset <= 400; offset++) {
      store.progress.dailyStats[
          keyFor(DateTime(now.year, now.month, now.day - offset))] = [1, 1];
    }

    await store.recordAnswer('letters', true);

    final days = store.progress.dailyStats.keys.toList()..sort();
    expect(ProgressStore.maxDailyStatsDays, 366);
    expect(days, hasLength(366));
    expect(days.last, keyFor(now));
    expect(days.first, keyFor(DateTime(now.year, now.month, now.day - 365)));
    expect(store.progress.streak, 366);
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

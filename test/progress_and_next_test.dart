import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/main.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/pages/child_detail_page.dart';
import 'package:tinymind/services/progress_store.dart';

Future<void> _pumpRow(
  WidgetTester tester, {
  required int answered,
  required int correct,
  required int completed,
  required int total,
  required int stars,
  required int totalStars,
  Size size = const Size(568, 320),
  double scale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SubjectProgressRow(
              module: learningModules.first,
              answered: answered,
              correct: correct,
              completedActivities: completed,
              totalActivities: total,
              stars: stars,
              totalStars: totalStars,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProgressStore _store(int age, [Map<String, int> stars = const {}]) {
  final store = ProgressStore();
  store.progress = UserProgress(childAge: age, activityStars: {...stars});
  return store;
}

void main() {
  group('SubjectProgressRow', () {
    testWidgets('finished world shows 100% with accuracy below',
        (tester) async {
      await _pumpRow(tester,
          answered: 60,
          correct: 58,
          completed: 20,
          total: 20,
          stars: 60,
          totalStars: 60);
      expect(find.text('100%'), findsOneWidget);
      expect(find.textContaining('97% correct'), findsOneWidget);
      expect(find.textContaining('20 / 20 activities'), findsOneWidget);
      final bar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator));
      expect(bar.value, 1.0);
    });

    testWidgets('partly done world shows completion, not accuracy',
        (tester) async {
      await _pumpRow(tester,
          answered: 20,
          correct: 17,
          completed: 3,
          total: 26,
          stars: 9,
          totalStars: 78);
      expect(find.text('12%'), findsOneWidget);
      expect(find.textContaining('85% correct'), findsOneWidget);
      expect(find.text('85%'), findsNothing);
    });

    testWidgets('untouched world says Not started without "correct"',
        (tester) async {
      await _pumpRow(tester,
          answered: 0,
          correct: 0,
          completed: 0,
          total: 26,
          stars: 0,
          totalStars: 78);
      expect(find.text('Not started'), findsOneWidget);
      expect(find.textContaining('correct'), findsNothing);
    });

    testWidgets('answered but no stars shows 0%', (tester) async {
      await _pumpRow(tester,
          answered: 5,
          correct: 2,
          completed: 0,
          total: 26,
          stars: 0,
          totalStars: 78);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Not started'), findsNothing);
      expect(find.textContaining('40% correct'), findsOneWidget);
    });

    testWidgets('fits 568x320 at text scale 1.3', (tester) async {
      await _pumpRow(tester,
          answered: 60,
          correct: 58,
          completed: 26,
          total: 26,
          stars: 78,
          totalStars: 78,
          scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  });

  group('nextActivityForResult', () {
    String? next(String world, int age, String id) =>
        nextActivityForResult(worldId: world, age: age, currentId: id);

    test('young children wrap to the first suitable activity', () {
      expect(next('colors', 3, 'colors_08'), 'colors_01');
      expect(next('colors', 3, 'colors_04'), 'colors_05');
      expect(next('numbers', 3, 'numbers_15'), 'numbers_01');
    });

    test('hand-picked above-age activities follow the world order', () {
      expect(next('numbers', 3, 'numbers_16'), 'numbers_17');
      expect(next('numbers', 3, 'numbers_20'), 'numbers_01');
    });

    test('older children', () {
      expect(next('colors', 5, 'colors_08'), 'colors_09');
      expect(next('colors', 5, 'colors_12'), 'colors_01');
    });

    test('unknown id gives null; every activity has a next', () {
      expect(next('colors', 5, 'nope'), isNull);
      for (final entry in worldCatalogs.entries) {
        for (final age in [3, 4, 5, 6]) {
          for (final a in entry.value.activities) {
            expect(next(entry.key, age, a.id), isNotNull);
          }
        }
      }
    });
  });

  group('ResultPage Next button', () {
    Future<void> pump(
      WidgetTester tester,
      LearningModule world,
      Activity activity,
      ProgressStore store, {
      Size size = const Size(568, 320),
      double scale = 1.0,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: ResultPage(
            world: world,
            activity: activity,
            score: 3,
            stars: 3,
            store: store,
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('Next is on every activity, even fully starred worlds',
        (tester) async {
      for (final world in learningModules) {
        final activities = worldCatalogs[world.id]!.activities;
        final full = {for (final a in activities) a.id: 3};
        for (final activity in activities) {
          for (final age in [3, 6]) {
            await pump(tester, world, activity, _store(age, full));
            expect(find.text('Next'), findsOneWidget,
                reason: '${activity.id} age $age');
            expect(find.text('Play again'), findsOneWidget);
            expect(find.text('Back to library'), findsOneWidget);
            expect(tester.takeException(), isNull,
                reason: '${activity.id} age $age');
          }
        }
      }
    });

    testWidgets('three actions and full-world hint fit at 568x320 and 1.3x',
        (tester) async {
      for (final world in learningModules) {
        final activities = worldCatalogs[world.id]!.activities;
        final full = {for (final a in activities) a.id: 3};
        final activity = activities.last;
        await pump(tester, world, activity, _store(6, full), scale: 1.3);
        expect(find.text('Next'), findsOneWidget, reason: activity.id);
        expect(find.text('Play again'), findsOneWidget, reason: activity.id);
        expect(find.text('Back to library'), findsOneWidget,
            reason: activity.id);
        final hint = find.textContaining('You finished everything here!');
        expect(hint, findsOneWidget, reason: activity.id);

        final screenRect = Offset.zero & const Size(568, 320);
        for (final finder in [
          find.text('Next'),
          find.text('Play again'),
          find.text('Back to library'),
          hint,
        ]) {
          final rect = tester.getRect(finder);
          expect(screenRect.contains(rect.topLeft), isTrue,
              reason: '${activity.id}: $rect outside $screenRect');
          expect(screenRect.contains(rect.bottomRight), isTrue,
              reason: '${activity.id}: $rect outside $screenRect');
        }
        expect(tester.takeException(), isNull, reason: activity.id);
      }
    });

    testWidgets('no hint when something is still worth playing',
        (tester) async {
      final world = learningModules.firstWhere((w) => w.id == 'colors');
      final activities = worldCatalogs['colors']!.activities;
      await pump(tester, world, activities.first, _store(5));
      expect(find.text('Next'), findsOneWidget);
      expect(
          find.textContaining('You finished everything here!'), findsNothing);
    });
  });
}

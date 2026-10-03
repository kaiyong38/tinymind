import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/main.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/pages/auth_pages.dart';
import 'package:tinymind/pages/child_detail_page.dart';
import 'package:tinymind/services/auth_service.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/widgets/drag_answer.dart';

void _setCompactLandscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(640, 390);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('home keeps its learning card clear of the floating menu',
      (tester) async {
    _setCompactLandscape(tester);
    await tester.pumpWidget(
      MaterialApp(home: TinyMindHomeShell(store: ProgressStore())),
    );
    await tester.pump();

    final menu = tester.getRect(find.byIcon(Icons.menu_rounded));
    final firstWorld = tester.getRect(find.byKey(const Key('module-letters')));
    expect(firstWorld.top, greaterThanOrEqualTo(menu.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome page fits and stretches both role buttons',
      (tester) async {
    _setCompactLandscape(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomePage(
          store: ProgressStore(),
          auth: _TestAuthService(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Add learners, view progress'), findsOneWidget);
    expect(find.text('Choose your picture to play'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result page presents all actions without scrolling',
      (tester) async {
    _setCompactLandscape(tester);
    final activity = worldCatalogs['letters']!.activities.first;
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          world: learningModules.first,
          activity: activity,
          score: 3,
          stars: 3,
          store: ProgressStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Back to library'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('answer area fits its allotted compact landscape height',
      (tester) async {
    _setCompactLandscape(tester);
    const question = QuizQuestion(
      prompt: 'Pick the picture',
      options: [
        QuizOption('Apple', emoji: '🍎'),
        QuizOption('Ball', emoji: '⚽'),
        QuizOption('Cat', emoji: '🐱'),
      ],
      answerIndex: 0,
      visual: AnswerVisual.picture,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              height: 195,
              child: DragAnswerArea(
                question: question,
                selectedIndex: null,
                answered: false,
                moduleColor: Colors.purple,
                onDrop: _ignoreAnswer,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly chart fits a short landscape screen', (tester) async {
    _setCompactLandscape(tester);
    final today = DateTime.now();
    final dateKey =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: WeekChart(dailyStats: {dateKey: const [12, 9]}),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

void _ignoreAnswer(int index) {}

class _TestAuthService implements AuthService {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

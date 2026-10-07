import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/accessibility_settings.dart';
import 'package:tinymind/widgets/drag_answer.dart';
import 'package:tinymind/widgets/question_cue_card.dart';
import 'package:tinymind/widgets/quiz_visuals.dart';

void main() {
  testWidgets('shapes_12 Q2 hill cue renders across landscape card sizes',
      (tester) async {
    final activity = worldCatalogs['shapes']!
        .activities
        .singleWhere((activity) => activity.id == 'shapes_12');
    final question = activity.questions[1];

    expect(question.cue, isA<RollingSlopeCue>());
    expect(question.prompt, 'Rolls down?');
    expect(question.spokenText, 'Which shape rolls down the hill?');
    expect(question.hint, 'Think of a ball.');
    expect(question.playType, PlayType.concept);
    expect(question.answerIndex, 0);
    expect(
      question.options.map((option) => option.label).toList(),
      ['circle', 'square', 'triangle'],
    );

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dimensions in [const Size(568, 320), const Size(640, 360)]) {
      tester.view.physicalSize = dimensions;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCueCard(
              question: question,
              worldColor: Colors.blue,
              onReplay: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cuePaint = find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.size.width > 400,
      );
      expect(cuePaint, findsOneWidget);
      final paint = tester.renderObject<RenderCustomPaint>(
        cuePaint,
      );
      expect(paint.size.width, greaterThan(400));
      expect(paint.size.height, greaterThan(100));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('color-friendly mode toggles swatch patterns and names',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AccessibilitySettings();
    await settings.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AccessibilitySettingsScope(
          settings: settings,
          child: Scaffold(
            body: Column(
              children: [
                Builder(
                  builder: (context) => SwitchListTile(
                    title: const Text('Color-friendly mode'),
                    value: AccessibilitySettingsScope.of(context)
                        .colorFriendlyMode,
                    onChanged: settings.setColorFriendlyMode,
                  ),
                ),
                Builder(
                  builder: (context) => buildQuizVisual(
                    context,
                    const QuizOption('Red', color: Colors.red),
                    AnswerVisual.colorSwatch,
                    size: 80,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final patternFinder = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint && widget.painter is ColorPatternPainter,
    );
    expect(patternFinder, findsNothing);
    expect(find.text('Red'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(patternFinder, findsOneWidget);
    expect(find.text('Red'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(patternFinder, findsNothing);
    expect(find.text('Red'), findsNothing);
  });

  testWidgets('color names fit in options and the selected answer preview',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AccessibilitySettings();
    await settings.load();
    await settings.setColorFriendlyMode(true);
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final question = worldCatalogs.values
        .expand((catalog) => catalog.activities)
        .expand((activity) => activity.questions)
        .firstWhere((question) => question.visual == AnswerVisual.colorSwatch);
    await tester.pumpWidget(
      AccessibilitySettingsScope(
        settings: settings,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 170,
              child: DragAnswerArea(
                question: question,
                selectedIndex: 2,
                answered: false,
                moduleColor: Colors.orange,
                onDrop: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (final label in find.byType(Text).evaluate()) {
      final text = (label.widget as Text).data;
      if (text == 'Orange') {
        final paragraph = label.renderObject as RenderParagraph;
        expect(
          paragraph.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text!.length),
          ),
          hasLength(1),
        );
      }
    }
    expect(find.text('Orange'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

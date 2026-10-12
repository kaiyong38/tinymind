@Tags(['overflow'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/main.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/accessibility_settings.dart';
import 'package:tinymind/services/narration_service.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/theme/app_theme.dart';
import 'package:tinymind/widgets/emoji_glyph.dart';
import 'package:tinymind/widgets/large_screen_scaler.dart';
import 'package:tinymind/widgets/question_cue_card.dart';

const _compactSizes = [Size(568, 320), Size(640, 360)];
const _cueMatrixSizes = [
  Size(568, 320),
  Size(640, 360),
  Size(732, 412),
  Size(851, 393),
  Size(1024, 600),
  Size(1024, 768),
  Size(1280, 800),
  Size(1920, 1080),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'full QuizPage renders every question state for all activities',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final issues = <String>[];
      final activities =
          worldCatalogs.values.expand((catalog) => catalog.activities);
      expect(activities.length, 70);

      for (final activity in activities) {
        final colorModes =
            activity.id.startsWith('colors_') ? [false, true] : [false];
        for (final size in _compactSizes) {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          for (final colorFriendly in colorModes) {
            final store = ProgressStore();
            final settings = AccessibilitySettings();
            final narration = _FakeNarrationService();
            await settings.setColorFriendlyMode(colorFriendly);
            await _pumpQuiz(
              tester,
              activity,
              store: store,
              settings: settings,
              narration: narration,
              size: size,
              scale: 1.3,
            );

            if (activity.questions.first.teach != null) {
              issues.addAll(await _inspectState(
                tester,
                activity,
                activity.questions.first,
                size,
                1.3,
                'teach',
                requireQuestionCard: false,
              ));
              final previousCalls = narration.calls.length;
              final bubble = _teachingBubbleFinder();
              if (bubble.evaluate().isNotEmpty) {
                await tester.tap(bubble.first);
                await tester.pump();
                if (narration.calls.length <= previousCalls) {
                  issues.add(_issue(
                    activity,
                    size,
                    1.3,
                    'teaching bubble tap did not replay narration',
                  ));
                }
              } else {
                issues.add(_issue(
                  activity,
                  size,
                  1.3,
                  'teaching text is not tappable or visible',
                ));
              }
              await _tapTeachContinue(tester);
              await tester.pumpAndSettle();
              if (find.byType(QuestionCueCard).evaluate().isEmpty) {
                throw StateError(
                  '${activity.id} $size, 1.3x: teaching continue '
                  'did not open Q1',
                );
              }
            }

            for (var questionIndex = 0;
                questionIndex < activity.questions.length;
                questionIndex++) {
              final question = activity.questions[questionIndex];
              issues.addAll(await _inspectState(
                tester,
                activity,
                question,
                size,
                1.3,
                'Q${questionIndex + 1} initial',
              ));

              final speaker = find.byIcon(Icons.volume_up_rounded);
              final replayCount = narration.calls.length;
              final questionCard = find.byType(QuestionCueCard);
              if (questionCard.evaluate().length != 1) {
                throw StateError(
                  '${activity.id} Q${questionIndex + 1}: expected one '
                  'question card after the teaching screen',
                );
              }
              final cardRect = tester.getRect(questionCard);
              await tester.tapAt(cardRect.center);
              await tester.pump();
              if (narration.calls.length <= replayCount) {
                issues.add(_issue(
                  activity,
                  size,
                  1.3,
                  'question card tap did not replay narration',
                ));
              }
              if (find
                  .descendant(
                    of: find.byType(AppBar),
                    matching: find.byIcon(Icons.volume_up_rounded),
                  )
                  .evaluate()
                  .isNotEmpty) {
                issues.add(_issue(
                  activity,
                  size,
                  1.3,
                  'quiz header contains a narration button',
                ));
              }
              if (speaker.evaluate().length != 1) {
                issues.add(_issue(
                  activity,
                  size,
                  1.3,
                  'question card does not show exactly one speaker icon',
                ));
              }

              final wrongIndex = (question.answerIndex + 1) % 3;
              await tester.tap(
                find.byKey(ValueKey('drag-answer-option-$wrongIndex')),
              );
              await tester.pump(const Duration(milliseconds: 200));
              issues.addAll(await _inspectState(
                tester,
                activity,
                question,
                size,
                1.3,
                'Q${questionIndex + 1} selected',
              ));

              await _submitOption(tester, wrongIndex);
              issues.addAll(await _inspectState(
                tester,
                activity,
                question,
                size,
                1.3,
                'Q${questionIndex + 1} wrong feedback dialog',
                requireQuestionCard: false,
              ));
              await _tapDialogAction(tester);
              await tester.pumpAndSettle();

              await tester.tap(
                find.byKey(
                  ValueKey('drag-answer-option-${question.answerIndex}'),
                ),
              );
              await tester.pump(const Duration(milliseconds: 200));
              await _submitOption(tester, question.answerIndex);
              issues.addAll(await _inspectState(
                tester,
                activity,
                question,
                size,
                1.3,
                'Q${questionIndex + 1} correct feedback dialog',
                requireQuestionCard: false,
              ));
              await _tapDialogAction(tester);
              await tester.pumpAndSettle();
            }
            store.dispose();
            settings.dispose();
          }
        }
      }

      expect(issues, isEmpty, reason: issues.join('\n'));
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );

  testWidgets(
    'each cue type fits the full landscape size and text-scale matrix',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final questionsByCueType = <Type, (Activity, QuizQuestion)>{};
      for (final activity
          in worldCatalogs.values.expand((catalog) => catalog.activities)) {
        for (final question in activity.questions) {
          final cue = question.cue;
          if (cue != null) {
            questionsByCueType.putIfAbsent(
              cue.runtimeType,
              () => (activity, question),
            );
          }
        }
      }

      final issues = <String>[];
      for (final entry in questionsByCueType.entries) {
        final (activity, question) = entry.value;
        final colorModes =
            activity.id.startsWith('colors_') ? [false, true] : [false];
        for (final size in _cueMatrixSizes) {
          tester.view
            ..physicalSize = size
            ..devicePixelRatio = 1;
          for (final scale in [1.0, 1.3]) {
            for (final colorFriendly in colorModes) {
              final store = ProgressStore();
              final settings = AccessibilitySettings();
              await settings.setColorFriendlyMode(colorFriendly);
              await _pumpQuiz(
                tester,
                activity,
                store: store,
                settings: settings,
                narration: _FakeNarrationService(),
                size: size,
                scale: scale,
              );
              if (activity.questions.first.teach != null) {
                await _tapTeachContinue(tester);
                await tester.pumpAndSettle();
              }
              for (var index = 0; index < activity.questions.length; index++) {
                if (activity.questions[index] == question) break;
                await _answerAndAdvance(
                  tester,
                  activity.questions[index],
                );
              }
              issues.addAll(await _inspectState(
                tester,
                activity,
                question,
                size,
                scale,
                '${entry.key} cue, color-friendly=$colorFriendly',
              ));
              store.dispose();
              settings.dispose();
            }
          }
        }
      }

      expect(issues, isEmpty, reason: issues.join('\n'));
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}

Future<void> _pumpQuiz(
  WidgetTester tester,
  Activity activity, {
  required ProgressStore store,
  required AccessibilitySettings settings,
  required NarrationService narration,
  required Size size,
  required double scale,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  await tester.pumpWidget(
    AccessibilitySettingsScope(
      settings: settings,
      child: MaterialApp(
        key: UniqueKey(),
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: LargeScreenScaler(child: child!),
        ),
        home: QuizPage(
          activity: activity,
          store: store,
          narration: narration,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _submitOption(WidgetTester tester, int optionIndex) async {
  await tester.tap(
    find.byKey(ValueKey('drag-answer-option-$optionIndex')),
  );
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

Future<void> _tapTeachContinue(WidgetTester tester) async {
  final buttons = find.byType(FilledButton);
  if (buttons.evaluate().isEmpty) {
    throw StateError('Teaching screen has no continue button');
  }
  await tester.tap(buttons.last);
  await tester.pumpAndSettle();
}

Future<void> _tapDialogAction(WidgetTester tester) async {
  final action = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(FilledButton),
  );
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> _answerAndAdvance(
  WidgetTester tester,
  QuizQuestion question,
) async {
  await tester.tap(
    find.byKey(ValueKey('drag-answer-option-${question.answerIndex}')),
  );
  await tester.pump(const Duration(milliseconds: 150));
  await _submitOption(tester, question.answerIndex);
  await _tapDialogAction(tester);
}

Future<List<String>> _inspectState(
  WidgetTester tester,
  Activity activity,
  QuizQuestion question,
  Size size,
  double scale,
  String state, {
  bool requireQuestionCard = true,
}) async {
  final issues = <String>[];
  final context = '${activity.id}, $size, ${scale}x, $state';
  final screen = Offset.zero & size;

  Object? exception;
  while ((exception = tester.takeException()) != null) {
    issues.add('$context: render exception: $exception');
  }

  if (requireQuestionCard) {
    final questionCard = find.byType(QuestionCueCard);
    if (questionCard.evaluate().length != 1) {
      issues.add('$context: question card missing or duplicated');
    } else {
      final cardRect = tester.getRect(questionCard);
      final speaker = find.byIcon(Icons.volume_up_rounded);
      final prompt = find.descendant(
        of: questionCard,
        matching: find.text(question.prompt),
      );
      if (speaker.evaluate().length != 1) {
        issues.add('$context: card must contain exactly one speaker');
      } else {
        final speakerRect = tester.getRect(speaker);
        if (!_containsRect(cardRect, speakerRect)) {
          issues.add('$context: speaker is outside its card');
        }
        if (prompt.evaluate().isNotEmpty &&
            tester.getRect(prompt.first).overlaps(speakerRect)) {
          issues.add('$context: speaker overlaps the prompt');
        }
        final cueRegion = find.descendant(
          of: questionCard,
          matching: find.byType(Expanded),
        );
        if (cueRegion.evaluate().isNotEmpty &&
            tester.getRect(cueRegion.first).overlaps(speakerRect)) {
          issues.add('$context: speaker overlaps the cue region');
        }
      }
      if (!_containsRect(screen, cardRect)) {
        issues.add('$context: question card is outside the screen');
      }
    }
  } else {
    final speakerCount = find.byIcon(Icons.volume_up_rounded).evaluate().length;
    if (_isTeachingScreen(tester)) {
      final bubble = _teachingBubbleFinder();
      if (bubble.evaluate().length != 1) {
        issues.add('$context: teaching bubble is missing or duplicated');
      } else {
        final bubbleRect = tester.getRect(bubble);
        if (!_containsRect(screen, bubbleRect)) {
          issues.add('$context: teaching bubble is outside the screen');
        }
      }
      if (speakerCount != 1) {
        issues
            .add('$context: teaching bubble must contain exactly one speaker');
      }
    } else if (speakerCount > 1) {
      issues.add('$context: more than one speaker icon is visible');
    }
  }

  for (var index = 0; index < 3; index++) {
    final tile = find.byKey(ValueKey('drag-answer-option-card-$index'));
    if (tile.evaluate().isEmpty) continue;
    final rect = tester.getRect(tile);
    final tileSize = tester.getSize(tile);
    if (tileSize.width < 56 || tileSize.height < 56) {
      issues.add('$context: answer tile $index is smaller than 56 dp ($rect)');
    }
    if (!_containsRect(screen, rect)) {
      issues.add('$context: answer tile $index is outside the screen ($rect)');
    }
    final tileFinder = find.byKey(ValueKey('drag-answer-option-card-$index'));
    for (final glyph in find
        .descendant(of: tileFinder, matching: find.byType(EmojiGlyph))
        .evaluate()) {
      final glyphFinder = find.byWidget(glyph.widget);
      final glyphRect = tester.getRect(glyphFinder);
      if (!_containsRect(rect, glyphRect)) {
        issues.add('$context: answer tile $index clips its emoji');
      }
    }
  }

  final dialogs = find.byType(Dialog);
  if (dialogs.evaluate().isNotEmpty) {
    final dialogRect = tester.getRect(dialogs.last);
    if (!_containsRect(screen, dialogRect)) {
      issues.add('$context: feedback dialog is outside the screen');
    }
    final dialogAction = find.descendant(
      of: dialogs.last,
      matching: find.byType(FilledButton),
    );
    if (dialogAction.evaluate().length != 1) {
      issues.add('$context: feedback dialog action is missing or duplicated');
    } else {
      final actionRect = tester.getRect(dialogAction);
      if (!_containsRect(screen, actionRect)) {
        issues.add('$context: feedback dialog action is outside the screen');
      }
    }
  }

  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final text = widget.data;
    if (text == null ||
        text.contains(RegExp(r'\s')) ||
        text.runes.length > 12) {
      continue;
    }
    final renderObject = element.findRenderObject();
    if (renderObject is! RenderParagraph || text.isEmpty) continue;
    final boxes = renderObject.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: text.length),
    );
    if (boxes.map((box) => box.top).toSet().length > 1) {
      issues.add('$context: short word "$text" wraps');
    }
  }

  return issues;
}

bool _containsRect(Rect outer, Rect inner) =>
    inner.left >= outer.left &&
    inner.top >= outer.top &&
    inner.right <= outer.right &&
    inner.bottom <= outer.bottom;

bool _isTeachingScreen(WidgetTester tester) =>
    find.byType(Dialog).evaluate().isEmpty;

Finder _teachingBubbleFinder() => find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Hear the question again',
    );

String _issue(Activity activity, Size size, double scale, String issue) =>
    '${activity.id}, $size, ${scale}x: $issue';

class _FakeNarrationService implements NarrationService {
  final calls = <({String text, String? spokenText})>[];

  @override
  bool get voiceAvailable => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> speak(String text, {String? spokenText}) async {
    calls.add((text: text, spokenText: spokenText));
  }

  @override
  Future<void> stop() async {}
}

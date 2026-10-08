import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/main.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/widgets/question_cue_card.dart';
import 'package:tinymind/widgets/quiz_visuals.dart';

void main() {
  final numberActivities = worldCatalogs['numbers']!.activities;

  group('TenFrameCue dots', () {
    test('addition: red dots = first addend, ? dots = second addend', () {
      for (final index in [15, 16]) {
        for (final question in numberActivities[index].questions) {
          final cue = question.cue! as TenFrameCue;
          expect(cue.mode, TenFrameMode.addition);
          expect(cue.filledDots, cue.firstCount, reason: question.prompt);
          expect(cue.questionDots, cue.secondCount, reason: question.prompt);
          expect(cue.filledDots + cue.questionDots, lessThanOrEqualTo(10));
        }
      }
    });

    test('subtraction keeps its crossed-out dots only', () {
      for (final question in numberActivities[17].questions) {
        final cue = question.cue! as TenFrameCue;
        expect(cue.filledDots, cue.firstCount);
        expect(cue.questionDots, 0);
      }
    });

    test('makeTen: ? dots fill the remaining cells', () {
      for (final question in numberActivities[18].questions) {
        final cue = question.cue! as TenFrameCue;
        expect(cue.filledDots, cue.firstCount);
        expect(cue.questionDots, 10 - cue.firstCount);
      }
    });

    test('teenNumber: full first frame, ? dots = second addend', () {
      for (final question in numberActivities[19].questions) {
        final cue = question.cue! as TenFrameCue;
        expect(cue.filledDots, 10);
        expect(cue.questionDots, cue.secondCount);
      }
    });
  });

  group('no corner "?" badge', () {
    testWidgets('take-away cues (numbers_14, 15) have no "?" text',
        (tester) async {
      for (final index in [13, 14]) {
        for (final question in numberActivities[index].questions) {
          await tester.pumpWidget(_card(question));
          expect(find.text('?'), findsNothing, reason: question.prompt);
        }
      }
    });

    testWidgets('equation picture keeps its "= ?"', (tester) async {
      final question = numberActivities
          .expand((activity) => activity.questions)
          .firstWhere((question) => question.cue is EquationPictureCue);
      await tester.pumpWidget(_card(question));
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('ten-frame cues leave the bottom-right corner empty',
        (tester) async {
      for (final index in [15, 16, 17, 18, 19]) {
        for (final question in numberActivities[index].questions) {
          final pixels = await _renderCue(tester, question.cue!);
          expect(
            _pixel(pixels, 352, 252),
            const Color(0xFFFFFFFF),
            reason: '${numberActivities[index].id} ${question.prompt}',
          );
        }
      }
    });

    testWidgets('? dots are drawn grey and red dots red', (tester) async {
      final addition = await _renderCue(
        tester,
        const TenFrameCue(
          mode: TenFrameMode.addition,
          firstCount: 3,
          secondCount: 3,
        ),
      );
      // Cell 0 centre is a red dot; cell 3 is a grey "?" dot (sampled off the
      // glyph).
      expect(_close(_pixel(addition, 85, 120), const Color(0xFFE84855)), isTrue);
      expect(_close(_pixel(addition, 245, 120), const Color(0xFFF1EDED)), isTrue);
      // Cells 3-5 are "?" dots; cell 6 (second row) is still empty.
      expect(_pixel(addition, 142, 180), const Color(0xFFFFFFFF));

      final teen = await _renderCue(
        tester,
        const TenFrameCue(
          mode: TenFrameMode.teenNumber,
          firstCount: 10,
          secondCount: 3,
        ),
      );
      expect(_pixel(teen, 5, 5), const Color(0xFFFFFFFF));
    });
  });

  group('read again', () {
    testWidgets('question card shows one speaker and replays on tap',
        (tester) async {
      var replays = 0;
      final question = numberActivities.first.questions.first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestionCueCard(
              question: question,
              worldColor: Colors.orange,
              onReplay: () => replays++,
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.volume_up_rounded),
          warnIfMissed: false);
      expect(replays, 1);
      await tester.tap(find.text(question.prompt));
      expect(replays, 2);
    });

    testWidgets('speaker never overlaps the prompt or the cue',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final questions = worldCatalogs.values
          .expand((catalog) => catalog.activities)
          .expand((activity) => activity.questions)
          .toList();
      final longest = questions
          .where((question) => question.prompt == 'What is missing?')
          .toList();
      expect(longest, isNotEmpty);
      for (final size in [const Size(568, 320), const Size(640, 360)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        for (final scale in [1.0, 1.3]) {
          for (final question in questions) {
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(scale),
                ),
                child: MaterialApp(
                  home: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: QuestionCueCard(
                              question: question,
                              worldColor: Colors.orange,
                              onReplay: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(flex: 4, child: SizedBox.shrink()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
            final reason = '${question.prompt}, $size, ${scale}x';
            final speaker = tester.getRect(find.byIcon(Icons.volume_up_rounded));
            final card = tester.getRect(find.byType(QuestionCueCard));
            expect(card.contains(speaker.topLeft), isTrue, reason: reason);
            expect(card.contains(speaker.bottomRight), isTrue, reason: reason);
            final prompt = find.text(question.prompt);
            if (prompt.evaluate().isNotEmpty) {
              expect(
                tester.getRect(prompt.first).overlaps(speaker),
                isFalse,
                reason: reason,
              );
            }
            if (question.cue != null) {
              final cueArea = tester.getRect(
                find.descendant(
                  of: find.byType(QuestionCueCard),
                  matching: find.byType(Expanded),
                ).first,
              );
              expect(cueArea.overlaps(speaker), isFalse, reason: reason);
            }
            expect(tester.takeException(), isNull, reason: reason);
          }
        }
      }
    });

    testWidgets('teaching bubble replays on tap and has one speaker',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      var speaks = 0;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'),
          (call) async {
        if (call.method == 'speak') speaks++;
        return 1;
      });
      messenger.setMockMethodCallHandler(
        const MethodChannel('tinymind/speech_audio_focus'),
        (call) async => true,
      );
      addTearDown(() {
        messenger.setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), null);
        messenger.setMockMethodCallHandler(
            const MethodChannel('tinymind/speech_audio_focus'), null);
      });
      final activity = numberActivities
          .firstWhere((activity) => activity.questions.first.teach != null);

      await tester.pumpWidget(
        MaterialApp(
          home: QuizPage(activity: activity, store: ProgressStore()),
        ),
      );
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();

      // The app bar has no read-aloud button; the bubble has the only speaker.
      expect(find.byTooltip('Read it again'), findsNothing);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.volume_up_rounded),
        ),
        findsNothing,
      );
      final before = speaks;
      await tester.tap(find.byIcon(Icons.volume_up_rounded),
          warnIfMissed: false);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      expect(speaks, before + 1);
    });
  });

  group('activity numbers', () {
    testWidgets('every activity card is numbered 1..N without repeats',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(1000, 9000);
      tester.view.devicePixelRatio = 1;
      for (final module in learningModules) {
        final total = worldCatalogs[module.id]!.activities.length;
        await tester.pumpWidget(
          MaterialApp(
            home: LibraryPage(world: module, store: ProgressStore()),
          ),
        );
        await tester.pump();
        final badges = find.byWidgetPredicate((widget) {
          final key = widget.key;
          return key is ValueKey<String> &&
              key.value.startsWith('activity-number-');
        });
        expect(badges, findsNWidgets(total), reason: module.id);
        final numbers = badges
            .evaluate()
            .map((element) => int.parse(
                  (find
                          .descendant(
                            of: find.byWidget(element.widget),
                            matching: find.byType(Text),
                          )
                          .evaluate()
                          .single
                          .widget as Text)
                      .data!,
                ))
            .toList()
          ..sort();
        expect(numbers, List.generate(total, (index) => index + 1),
            reason: module.id);
        expect(find.bySemanticsLabel(RegExp(r'Activity 1(\n|$)')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Activity $total(\\n|\$)')),
            findsOneWidget);
      }
      handle.dispose();
    });

    testWidgets('number badge does not overlap "Try this!" at 568x320, 1.3x',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      const size = Size(568, 320);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      for (final module in learningModules) {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
            ),
            child: MaterialApp(
              home: LibraryPage(world: module, store: ProgressStore()),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: module.id);
        final badge = tester.getRect(find.byKey(ValueKey(
            'activity-number-${worldCatalogs[module.id]!.activities.first.id}')));
        final tryThis = find.textContaining('Try this!');
        if (tryThis.evaluate().isNotEmpty) {
          expect(tester.getRect(tryThis.first).overlaps(badge), isFalse,
              reason: module.id);
        }
      }
    });
  });
}

Widget _card(QuizQuestion question) => MaterialApp(
      home: Scaffold(
        body: QuestionCueCard(
          question: question,
          worldColor: Colors.orange,
          onReplay: () {},
        ),
      ),
    );

/// Renders [cue] on white at 400x300 and returns raw RGBA pixels.
Future<ByteData> _renderCue(WidgetTester tester, QuizCue cue) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: Container(
            color: Colors.white,
            width: 400,
            height: 300,
            child: buildQuestionCue(cue, size: 300),
          ),
        ),
      ),
    ),
  );
  final data = await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    return image.toByteData(format: ui.ImageByteFormat.rawRgba);
  });
  return data!;
}

Color _pixel(ByteData data, int x, int y) {
  final offset = (y * 400 + x) * 4;
  return Color.fromARGB(
    data.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  );
}

bool _close(Color a, Color b) =>
    ((a.r - b.r) * 255).abs() < 8 &&
    ((a.g - b.g) * 255).abs() < 8 &&
    ((a.b - b.b) * 255).abs() < 8;

@Tags(['overflow'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/main.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/pages/achievement_page.dart';
import 'package:tinymind/pages/admin_page.dart';
import 'package:tinymind/pages/auth_pages.dart';
import 'package:tinymind/pages/child_detail_page.dart';
import 'package:tinymind/pages/parent_gate_pages.dart';
import 'package:tinymind/pages/parent_settings_page.dart';
import 'package:tinymind/pages/privacy_policy_page.dart';
import 'package:tinymind/services/accessibility_settings.dart';
import 'package:tinymind/services/auth_service.dart';
import 'package:tinymind/services/firestore_service.dart';
import 'package:tinymind/services/parent_gate_service.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/theme/app_theme.dart';
import 'package:tinymind/widgets/drag_answer.dart';
import 'package:tinymind/widgets/emoji_glyph.dart';
import 'package:tinymind/widgets/large_screen_scaler.dart';
import 'package:tinymind/widgets/question_cue_card.dart';
import 'package:tinymind/widgets/text_scale_limit.dart';

final _theme = buildAppTheme();
late AccessibilitySettings _accessibilitySettings;
late void Function(FlutterErrorDetails details)? _previousFlutterErrorHandler;
final _capturedFlutterErrors = <FlutterErrorDetails>[];

void main() {
  setUp(() async {
    _previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      _capturedFlutterErrors.add(details);
      _previousFlutterErrorHandler?.call(details);
    };
    SharedPreferences.setMockInitialValues({});
    _accessibilitySettings = AccessibilitySettings();
    await _accessibilitySettings.load();
  });
  tearDown(() {
    FlutterError.onError = _previousFlutterErrorHandler;
    _capturedFlutterErrors.clear();
  });

  testWidgets('all answer-option emoji use EmojiGlyph and fit their tiles',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sizes = [const Size(640, 360), const Size(568, 320)];
    for (final size in sizes) {
      for (final activity
          in worldCatalogs.values.expand((catalog) => catalog.activities)) {
        for (final question in activity.questions) {
          final colorModes = question.visual == AnswerVisual.colorSwatch
              ? [false, true]
              : [false];
          for (final colorFriendly in colorModes) {
            for (final scale in [1.0, 1.3]) {
              for (final state in _questionStates(question)) {
                await pumpScreen(
                  tester,
                  Scaffold(
                    body: DragAnswerArea(
                      question: question,
                      selectedIndex: state.selectedIndex,
                      answered: state.answered,
                      moduleColor: Colors.orange,
                      onDrop: (_) {},
                    ),
                  ),
                  size,
                  scale,
                  colorFriendly: colorFriendly,
                );
                if (state.name == 'selected') {
                  await tester.tap(
                    find.byKey(const ValueKey('drag-answer-option-0')),
                  );
                  await tester.pump();
                }

                for (var index = 0; index < question.options.length; index++) {
                  final option = question.options[index];
                  if (option.emoji == null ||
                      !_showsEmoji(question.visual) ||
                      question.visual == AnswerVisual.numberDots &&
                          (option.count ?? 0) == 0) {
                    continue;
                  }

                  final card = find.byKey(
                    ValueKey('drag-answer-option-card-$index'),
                  );
                  expect(card, findsOneWidget);
                  final tileSize = tester.getSize(card);
                  expect(tileSize.width, greaterThanOrEqualTo(56));
                  expect(tileSize.height, greaterThanOrEqualTo(56));
                  final glyphs = find.descendant(
                    of: card,
                    matching: find.byType(EmojiGlyph),
                  );
                  final expectedGlyphs =
                      question.visual == AnswerVisual.numberDots
                          ? option.count ?? 0
                          : 1;
                  expect(
                    glyphs,
                    findsNWidgets(expectedGlyphs),
                    reason:
                        '${activity.title}: ${option.label} at $size, ${scale}x, state ${state.name}',
                  );

                  final cardRect = tester.getRect(card);
                  final contentRect = cardRect.deflate(6);
                  for (final glyph in glyphs.evaluate()) {
                    final glyphFinder = find.byWidget(glyph.widget);
                    final glyphRect = tester.getRect(glyphFinder);
                    expect(
                      _containsRect(contentRect, glyphRect),
                      isTrue,
                      reason:
                          '${activity.title}: glyph outside tile content at $size, ${scale}x, state ${state.name}',
                    );

                    final textFinder = find.descendant(
                      of: glyphFinder,
                      matching: find.byType(Text),
                    );
                    expect(textFinder, findsOneWidget);
                    expect(
                      _containsRect(glyphRect, tester.getRect(textFinder)),
                      isTrue,
                      reason:
                          '${activity.title}: glyph text outside EmojiGlyph square at $size, ${scale}x, state ${state.name}',
                    );
                  }
                }

                _expectNoException(
                  tester,
                  'Quiz ${activity.title}, ${question.prompt}, $size, ${scale}x, color-friendly=$colorFriendly, ${state.name}',
                );
                _expectSingleLineWords(
                  tester,
                  'Quiz ${activity.title}, $size, ${scale}x, ${state.name}',
                );
                _expectClippedChildrenWithinParents(
                  tester,
                  'Quiz ${activity.title}, ${question.prompt}, $size, ${scale}x, color-friendly=$colorFriendly, ${state.name}',
                );
              }
            }
          }
        }
      }
    }
  });

  testWidgets('emoji glyphs fit the full quiz size and text-scale matrix',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final allQuestions = worldCatalogs.values
        .expand((catalog) => catalog.activities)
        .expand((activity) => activity.questions)
        .toList(growable: false);
    final representatives = <AnswerVisual, QuizQuestion>{};
    for (final question in allQuestions) {
      representatives.putIfAbsent(question.visual, () => question);
    }
    const sizes = [
      Size(568, 320),
      Size(640, 360),
      Size(732, 412),
      Size(851, 393),
      Size(1024, 600),
      Size(1024, 768),
      Size(1280, 800),
      Size(1920, 1080),
    ];
    for (final entry in representatives.entries) {
      final modes =
          entry.key == AnswerVisual.colorSwatch ? [false, true] : [false];
      for (final colorFriendly in modes) {
        for (final size in sizes) {
          for (final scale in [1.0, 1.3]) {
            final question = entry.value;
            await pumpScreen(
              tester,
              Scaffold(
                body: DragAnswerArea(
                  question: question,
                  selectedIndex: null,
                  answered: false,
                  moduleColor: Colors.orange,
                  onDrop: (_) {},
                ),
              ),
              size,
              scale,
              colorFriendly: colorFriendly,
            );

            final screenRect = Offset.zero & size;
            for (final card in find
                .byWidgetPredicate(
                  (widget) =>
                      widget.key is ValueKey<String> &&
                      (widget.key! as ValueKey<String>)
                          .value
                          .startsWith('drag-answer-option-card-'),
                )
                .evaluate()) {
              expect(
                _containsRect(
                  screenRect,
                  tester.getRect(find.byWidget(card.widget)),
                ),
                isTrue,
                reason:
                    'Quiz ${entry.key}, $size, ${scale}x, color-friendly=$colorFriendly',
              );
            }
            _expectNoException(
              tester,
              'Quiz ${entry.key}, $size, ${scale}x, color-friendly=$colorFriendly',
            );
            _expectSingleLineWords(
              tester,
              'Quiz ${entry.key}, $size, ${scale}x, color-friendly=$colorFriendly',
            );
            _expectClippedChildrenWithinParents(
              tester,
              'Quiz ${entry.key}, $size, ${scale}x, color-friendly=$colorFriendly',
            );
          }
        }
      }
    }
  });

  testWidgets('EmojiGlyph keeps multi-codepoint emoji intact', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const samples = ['👍🏽', '🇺🇸', '👨‍👩‍👧‍👦'];
    await pumpScreen(
      tester,
      const Scaffold(
        body: Wrap(
          children: [
            EmojiGlyph('👍🏽', 48),
            EmojiGlyph('🇺🇸', 48),
            EmojiGlyph('👨‍👩‍👧‍👦', 48),
          ],
        ),
      ),
      const Size(640, 360),
      1,
    );

    final glyphs = find.byType(EmojiGlyph);
    expect(glyphs, findsNWidgets(samples.length));
    for (var index = 0; index < samples.length; index++) {
      final glyph = tester.widget<EmojiGlyph>(glyphs.at(index));
      expect(glyph.emoji, samples[index]);
      final rect = tester.getRect(glyphs.at(index));
      final textRect = tester.getRect(
        find.descendant(
          of: glyphs.at(index),
          matching: find.byType(Text),
        ),
      );
      expect(_containsRect(rect, textRect), isTrue);
    }
    _expectNoException(tester, 'Multi-codepoint emoji, 640x360, 1x');
  });

  testWidgets('responsive screens fit every landscape size and text scale',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const sizes = [
      Size(568, 320),
      Size(640, 360),
      Size(732, 412),
      Size(851, 393),
      Size(1024, 600),
      Size(1024, 768),
      Size(1280, 800),
      Size(1920, 1080),
    ];
    final auth = AuthService(
      auth: _UnusedFirebaseAuth(),
      firestore: _AuditFirestore(),
    );
    final firestore = _AuditFirestore();
    final gateService = ParentGateService(
      storage: _AuditGateStorage(),
      phoneAuthenticator: _AuditPhoneAuthenticator(),
    );
    final cases = <_ScreenCase>[
      _ScreenCase('WelcomePage', [1, 1.3, 1.6], () {
        final store = _stressStore();
        return WelcomePage(store: store, auth: auth);
      }),
      _ScreenCase('LoginPage', [1, 1.3, 1.6], () => LoginPage(auth: auth)),
      _ScreenCase(
          'RegisterPage', [1, 1.3, 1.6], () => RegisterPage(auth: auth)),
      _ScreenCase('ForgotPasswordPage', [1, 1.3, 1.6],
          () => ForgotPasswordPage(auth: auth)),
      _ScreenCase('ChangePasswordPage', [1, 1.3, 1.6],
          () => ChangePasswordPage(auth: auth)),
      _ScreenCase('ChildProfilePage', [1, 1.3, 1.6], () {
        return ChildProfilePage(store: _stressStore(), auth: auth);
      }),
      _ScreenCase('ChildPickerPage', [1, 1.3, 1.6], () {
        return ChildPickerPage(
          store: _stressStore(),
          parentUid: 'parent-audit',
          firestore: firestore,
          auth: auth,
        );
      }),
      _ScreenCase('TinyMindHomeShell', [1, 1.3], () {
        return TinyMindHomeShell(store: _stressStore());
      }),
      _ScreenCase('LibraryPage', [1, 1.3], () {
        return LibraryPage(
          world: learningModules.first,
          store: _stressStore(),
        );
      }),
      _ScreenCase('QuizPage', [1, 1.3], () {
        final activity =
            worldCatalogs.values.expand((catalog) => catalog.activities).first;
        return QuizPage(activity: activity, store: _stressStore());
      }),
      _ScreenCase('ResultPage', [1, 1.3], () {
        return ResultPage(
          world: learningModules.first,
          activity: worldCatalogs.values
              .expand((catalog) => catalog.activities)
              .first,
          score: 3,
          stars: 3,
          store: _stressStore(),
        );
      }),
      _ScreenCase('AchievementPage', [1, 1.3], () {
        return AchievementPage(progress: _stressStore().progress);
      }),
      _ScreenCase('AvatarPage', [1, 1.3], () {
        return AvatarPage(store: _stressStore());
      }),
      _ScreenCase('ProgressPage', [1, 1.3], () {
        return ProgressPage(store: _stressStore());
      }),
      _ScreenCase('AdminPage', [1, 1.3, 1.6], () {
        return AdminPage(
          parentUid: 'parent-audit',
          firestore: firestore,
          auth: auth,
          gateService: gateService,
        );
      }),
      _ScreenCase('ParentSettingsPage', [1, 1.3, 1.6],
          () => ParentSettingsPage(gateService: gateService)),
      _ScreenCase('ChildDetailPage', [1, 1.3, 1.6], () {
        return ChildDetailPage(
          parentUid: 'parent-audit',
          childId: 'child-audit',
          summary: {
            'name': 'W' * 20,
            'avatar': '👨‍👩‍👧‍👦',
            'points': 99999,
            'age': 6,
            'totalQuestions': 999,
            'correctAnswers': 999,
            'dailyStats': <String, dynamic>{},
          },
          firestore: firestore,
        );
      }),
      _ScreenCase(
          'PrivacyPolicyPage', [1, 1.3, 1.6], () => const PrivacyPolicyPage()),
    ];

    for (final screen in cases) {
      for (final size in sizes) {
        for (final scale in screen.scales) {
          await pumpScreen(
            tester,
            screen.build(),
            size,
            scale,
          );
          _expectNoException(
            tester,
            '${screen.name}, $size, ${scale}x',
          );
          _expectSingleLineWords(
            tester,
            '${screen.name}, $size, ${scale}x',
          );
          _expectClippedChildrenWithinParents(
            tester,
            '${screen.name}, $size, ${scale}x',
          );
        }
      }
    }
  });

  testWidgets('all Shape cue cards fit small landscape and 1.6 text scale',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const sizes = [Size(568, 320), Size(640, 360)];
    final questions = worldCatalogs['shapes']!
        .activities
        .expand((activity) => activity.questions)
        .toList();

    for (final question in questions) {
      for (final size in sizes) {
        for (final scale in [1.0, 1.6]) {
          await pumpScreen(
            tester,
            Scaffold(
              appBar: AppBar(toolbarHeight: 48),
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: QuestionCueCard(
                        question: question,
                        worldColor: Colors.teal,
                        onReplay: () {},
                        revealDifference: question.cue is ShapeRowCue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(flex: 4, child: SizedBox.shrink()),
                  ],
                ),
              ),
            ),
            size,
            scale,
          );
          _expectNoException(
            tester,
            'QuestionCueCard ${question.cue!.runtimeType}, $size, ${scale}x',
          );
          _expectSpeakerClear(
            tester,
            question,
            'QuestionCueCard ${question.cue!.runtimeType}, $size, ${scale}x',
          );
          _expectClippedChildrenWithinParents(
            tester,
            'QuestionCueCard ${question.cue!.runtimeType}, $size, ${scale}x',
          );
        }
      }
    }
  });

  testWidgets('Numbers cue cards fit at compact sizes and enlarged text',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const sizes = [Size(568, 320), Size(640, 360)];
    final uniqueQuestions = <String, QuizQuestion>{};
    for (final question in worldCatalogs['numbers']!
        .activities
        .expand((activity) => activity.questions)) {
      if (question.cue is ItemCountCue ||
          question.cue is EquationPictureCue ||
          question.cue is TenFrameCue) {
        uniqueQuestions.putIfAbsent(
          question.cue!.identityKey,
          () => question,
        );
      }
    }

    for (final question in uniqueQuestions.values) {
      for (final size in sizes) {
        for (final scale in [1.0, 1.3]) {
          await pumpScreen(
            tester,
            Scaffold(
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
            size,
            scale,
          );
          _expectNoException(
            tester,
            'Numbers ${question.cue!.runtimeType}, $size, ${scale}x',
          );
          _expectSpeakerClear(
            tester,
            question,
            'Numbers ${question.cue!.runtimeType}, $size, ${scale}x',
          );
          _expectClippedChildrenWithinParents(
            tester,
            'Numbers ${question.cue!.runtimeType}, $size, ${scale}x',
          );
        }
      }
    }
  });

  testWidgets('Letter cue cards fit compact sizes and enlarged text',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const sizes = [Size(568, 320), Size(640, 360)];
    final uniqueQuestions = <String, QuizQuestion>{};
    for (final question in worldCatalogs['letters']!
        .activities
        .expand((activity) => activity.questions)) {
      if (question.cue is LetterCue) {
        uniqueQuestions.putIfAbsent(question.cue!.identityKey, () => question);
      }
    }

    for (final question in uniqueQuestions.values) {
      for (final size in sizes) {
        for (final scale in [1.0, 1.3]) {
          await pumpScreen(
            tester,
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 5,
                      child: QuestionCueCard(
                        question: question,
                        worldColor: Colors.blue,
                        onReplay: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(flex: 4, child: SizedBox.shrink()),
                  ],
                ),
              ),
            ),
            size,
            scale,
          );
          _expectNoException(
            tester,
            'Letters ${question.cue!.identityKey}, $size, ${scale}x',
          );
          _expectSpeakerClear(
            tester,
            question,
            'Letters ${question.cue!.identityKey}, $size, ${scale}x',
          );
          _expectClippedChildrenWithinParents(
            tester,
            'Letters ${question.cue!.identityKey}, $size, ${scale}x',
          );
        }
      }
    }
  });

  testWidgets('parent gate setup and PIN entry fit landscape text matrix',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const sizes = [
      Size(568, 320),
      Size(640, 360),
      Size(732, 412),
      Size(851, 393),
      Size(1024, 600),
      Size(1024, 768),
      Size(1280, 800),
      Size(1920, 1080),
    ];
    const phases = <(String, ParentLockMethod?, String, String)>[
      ('method selection', null, 'unlock', 'Set up grown-up lock'),
      ('set PIN', null, 'set-pin', 'Set a 4-digit PIN'),
      ('enter PIN', ParentLockMethod.pin, 'unlock', 'Grown-ups only'),
    ];
    for (final phase in phases) {
      for (final size in sizes) {
        for (final scale in [1.0, 1.3, 1.6]) {
          final storage = _AuditGateStorage(
            method: phase.$2,
            pinRecord: phase.$1 == 'enter PIN' ? 'fixture-record' : null,
          );
          final service = ParentGateService(
            storage: storage,
            phoneAuthenticator: _AuditPhoneAuthenticator(),
          );
          await pumpScreen(
            tester,
            _GateAuditHarness(
              service: service,
              action: phase.$3,
            ),
            size,
            scale,
          );
          final gateContext = tester.element(find.byType(Scaffold));
          if (phase.$3 == 'set-pin') {
            unawaited(service.usePin(gateContext));
          } else {
            unawaited(service.unlock(gateContext));
          }
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pumpAndSettle();
          _expectNoException(
            tester,
            'ParentGate ${phase.$1}, $size, ${scale}x',
          );
          expect(find.text(phase.$4), findsOneWidget);
          _expectSingleLineWords(
            tester,
            'ParentGate ${phase.$1}, $size, ${scale}x',
          );
          _expectClippedChildrenWithinParents(
            tester,
            'ParentGate ${phase.$1}, $size, ${scale}x',
          );
        }
      }
    }
  });

  testWidgets('parent child lists fit zero, one, four and eight children',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final count in [0, 1, 4, 8]) {
      for (final size in [const Size(568, 320), const Size(640, 360)]) {
        for (final scale in [1.0, 1.3, 1.6]) {
          final firestore = _AuditFirestore(childCount: count);
          final auth = AuthService(
            auth: _UnusedFirebaseAuth(),
            firestore: firestore,
          );
          final gateService = ParentGateService(
            storage: _AuditGateStorage(),
            phoneAuthenticator: _AuditPhoneAuthenticator(),
          );
          for (final page in [
            'ChildPickerPage',
            'AdminPage',
          ]) {
            final widget = page == 'ChildPickerPage'
                ? ChildPickerPage(
                    store: _stressStore(),
                    parentUid: 'parent-audit',
                    firestore: firestore,
                    auth: auth,
                  )
                : AdminPage(
                    parentUid: 'parent-audit',
                    firestore: firestore,
                    auth: auth,
                    gateService: gateService,
                  );
            await pumpScreen(tester, widget, size, scale);
            _expectNoException(
              tester,
              '$page, $count children, $size, ${scale}x',
            );
            _expectSingleLineWords(
              tester,
              '$page, $count children, $size, ${scale}x',
            );
          }
        }
      }
    }
  });

  testWidgets('long email remains renderable on the login page',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = AuthService(auth: _UnusedFirebaseAuth());
    for (final size in [const Size(568, 320), const Size(640, 360)]) {
      for (final scale in [1.0, 1.3, 1.6]) {
        await pumpScreen(tester, LoginPage(auth: auth), size, scale);
        await tester.enterText(
          find.byType(TextField).first,
          '${'W' * 90}@example-long-domain.test',
        );
        await tester.pump();
        _expectNoException(tester, 'LoginPage, long email, $size, ${scale}x');
      }
    }
  });
}

Future<void> pumpScreen(
  WidgetTester tester,
  Widget widget,
  Size size,
  double textScale, {
  bool colorFriendly = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  _capturedFlutterErrors.clear();
  await _accessibilitySettings.setColorFriendlyMode(colorFriendly);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        theme: _theme,
        builder: (context, child) => LargeScreenScaler(
          child: TextScaleLimit(
            maxScale: 1.6,
            child: child!,
          ),
        ),
        home: AccessibilitySettingsScope(
          settings: _accessibilitySettings,
          child: widget,
        ),
      ),
    ),
  );
  await tester.pump();
}

Iterable<_QuestionState> _questionStates(QuizQuestion question) sync* {
  yield const _QuestionState('initial', null, false);
  yield const _QuestionState('selected', 0, false);
  yield _QuestionState('correct feedback', question.answerIndex, true);
  yield _QuestionState(
    'incorrect feedback',
    (question.answerIndex + 1) % question.options.length,
    true,
  );
}

bool _showsEmoji(AnswerVisual visual) =>
    visual == AnswerVisual.picture ||
    visual == AnswerVisual.letterPicture ||
    visual == AnswerVisual.numberDots;

bool _containsRect(Rect parent, Rect child) =>
    parent.left <= child.left &&
    parent.top <= child.top &&
    parent.right >= child.right &&
    parent.bottom >= child.bottom;

void _expectClippedChildrenWithinParents(
  WidgetTester tester,
  String description,
) {
  for (final element in find.byWidgetPredicate((widget) {
    if (widget is ClipRect || widget is ClipRRect || widget is ClipOval) {
      return true;
    }
    return widget is FittedBox;
  }).evaluate()) {
    final widget = element.widget;
    final child = switch (widget) {
      ClipRect(:final child) => child,
      ClipRRect(:final child) => child,
      ClipOval(:final child) => child,
      FittedBox(:final child) => child,
      _ => null,
    };
    if (child == null) continue;
    final parentRenderObject = element.findRenderObject();
    final childElement = find.byWidget(child).evaluate().single;
    final childRenderObject = childElement.findRenderObject();
    if (parentRenderObject is! RenderBox || childRenderObject is! RenderBox) {
      continue;
    }
    if (widget is FittedBox) {
      final isLargeScreenStage =
          widget.key == const ValueKey('large-screen-scaler-stage');
      expect(
        widget.fit,
        isLargeScreenStage
            ? BoxFit.fill
            : anyOf(BoxFit.contain, BoxFit.scaleDown),
        reason: isLargeScreenStage
            ? '$description; the large-screen stage must fill the window'
            : '$description; FittedBox must not crop its child',
      );
      final parentRect = Offset.zero & parentRenderObject.size;
      final fittedSize = applyBoxFit(
        widget.fit,
        childRenderObject.size,
        parentRenderObject.size,
      );
      final fittedRect = widget.alignment
          .resolve(TextDirection.ltr)
          .inscribe(fittedSize.destination, parentRect);
      expect(
        _containsRect(parentRect, fittedRect),
        isTrue,
        reason: '$description; fitted child destination leaves FittedBox',
      );
      continue;
    }
    final parentRect = Offset.zero & parentRenderObject.size;
    final childRect = MatrixUtils.transformRect(
      childRenderObject.getTransformTo(parentRenderObject),
      Offset.zero & childRenderObject.size,
    );
    expect(
      _containsRect(parentRect, childRect),
      isTrue,
      reason: '$description; ${widget.runtimeType} child ${child.runtimeType} '
          'extends outside '
          '${parentRect.left.toStringAsPrecision(17)},'
          '${parentRect.top.toStringAsPrecision(17)},'
          '${parentRect.right.toStringAsPrecision(17)},'
          '${parentRect.bottom.toStringAsPrecision(17)} with '
          '${childRect.left.toStringAsPrecision(17)},'
          '${childRect.top.toStringAsPrecision(17)},'
          '${childRect.right.toStringAsPrecision(17)},'
          '${childRect.bottom.toStringAsPrecision(17)}; '
          'parentSize=${parentRenderObject.size}, '
          'childSize=${childRenderObject.size}, '
          'childWidget=$child',
    );
  }
}

void _expectSpeakerClear(
  WidgetTester tester,
  QuizQuestion question,
  String description,
) {
  final speaker = find.byIcon(Icons.volume_up_rounded);
  expect(speaker, findsOneWidget, reason: description);
  final speakerRect = tester.getRect(speaker);
  final prompt = find.text(question.prompt);
  if (prompt.evaluate().isNotEmpty) {
    expect(tester.getRect(prompt.first).overlaps(speakerRect), isFalse,
        reason: '$description: speaker overlaps prompt');
  }
}

void _expectNoException(WidgetTester tester, String description) {
  final exceptions = <Object>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    if (exception is FlutterError) {
      exceptions.add(
        '${exception.toString()}\n'
        '${exception.diagnostics.map((diagnostic) => diagnostic.toString()).join('\n')}',
      );
    } else {
      exceptions.add(exception!);
    }
  }
  exceptions.addAll(
    _capturedFlutterErrors.map((details) {
      final context = details.context?.toString() ?? '';
      final information = details.informationCollector
              ?.call()
              .map((node) => node.toString())
              .join('\n') ??
          '';
      return '${details.toString()}\n$context\n$information';
    }),
  );
  if (exceptions.isNotEmpty) {
    exceptions.addAll(_describeFlexBounds(tester));
  }
  _capturedFlutterErrors.clear();
  expect(
    exceptions,
    isEmpty,
    reason: '$description; exceptions: ${exceptions.join('\n')}',
  );
}

Iterable<String> _describeFlexBounds(WidgetTester tester) sync* {
  for (final element
      in find.byWidgetPredicate((widget) => widget is Flex).evaluate()) {
    final flex = element.findRenderObject();
    if (flex is! RenderFlex) continue;
    var child = flex.firstChild;
    while (child != null) {
      final data = child.parentData! as FlexParentData;
      final childRect = data.offset & child.size;
      final outOfBounds = flex.direction == Axis.horizontal
          ? childRect.left < 0 || childRect.right > flex.size.width
          : childRect.top < 0 || childRect.bottom > flex.size.height;
      if (outOfBounds) {
        final contents =
            child is RenderParagraph ? child.text.toPlainText() : '';
        yield '${element.widget.runtimeType}: flex=${flex.size}, '
            'child=$childRect ${child.runtimeType} '
            'text="$contents" ${child.debugCreator}';
      }
      child = flex.childAfter(child);
    }
  }
}

void _expectSingleLineWords(WidgetTester tester, String description) {
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final text = widget.data ?? _plainSpanText(widget.textSpan);
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
    if (boxes.isEmpty) continue;
    final lineTops = boxes.map((box) => box.top).toSet();
    expect(
      lineTops,
      hasLength(1),
      reason: '$description; "$text" rendered on ${lineTops.length} lines',
    );
  }
}

String? _plainSpanText(InlineSpan? span) {
  if (span == null) return null;
  if (span is WidgetSpan || span is! TextSpan) return null;
  final children = span.children;
  if (children == null) return span.text ?? '';
  final childText = StringBuffer();
  for (final child in children) {
    final text = _plainSpanText(child);
    if (text == null) return null;
    childText.write(text);
  }
  return '${span.text ?? ''}$childText';
}

class _QuestionState {
  const _QuestionState(this.name, this.selectedIndex, this.answered);

  final String name;
  final int? selectedIndex;
  final bool answered;
}

ProgressStore _stressStore() {
  final store = ProgressStore();
  store.progress = UserProgress(
    childName: 'W' * 20,
    avatar: '👨‍👩‍👧‍👦',
    childAge: 6,
    points: 99999,
    totalQuestions: 999,
    correctAnswers: 999,
    dailyStats: {
      for (var day = 1; day <= 100; day++)
        '2026-01-${day.toString().padLeft(2, '0')}': [1, 1],
    },
  );
  return store;
}

class _ScreenCase {
  const _ScreenCase(this.name, this.scales, this.build);

  final String name;
  final List<double> scales;
  final Widget Function() build;
}

class _UnusedFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;
}

class _AuditFirestore extends Fake implements FirestoreService {
  _AuditFirestore({this.childCount = 8});

  final int childCount;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchChildren(String parentUid) =>
      Stream.value(
        _AuditChildrenSnapshot(
          List.generate(childCount, _AuditChildDocument.new),
        ),
      );

  @override
  Future<Map<String, dynamic>?> loadProgress(
    String parentUid,
    String childId,
  ) async =>
      null;

  @override
  Future<void> backfillProfileFromProgress(
    String parentUid,
    String childId,
  ) async {}
}

// ignore: subtype_of_sealed_class
class _AuditChildrenSnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _AuditChildrenSnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

// ignore: subtype_of_sealed_class
class _AuditChildDocument extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _AuditChildDocument(this.index);

  final int index;

  @override
  String get id => 'child-$index';

  @override
  Map<String, dynamic> data() => {
        'name': 'W' * 20,
        'avatar': '👨‍👩‍👧‍👦',
        'age': 6,
        'points': 99999,
        'totalQuestions': 999,
        'correctAnswers': 999,
        'activityStars': <String, int>{},
        'dailyStats': <String, dynamic>{},
      };
}

class _AuditGateStorage extends Fake implements ParentGateStorage {
  _AuditGateStorage({this.method, this.pinRecord});

  final ParentLockMethod? method;
  final String? pinRecord;

  @override
  Future<ParentLockMethod?> readMethod() async => method;

  @override
  Future<void> writeMethod(ParentLockMethod method) async {}

  @override
  Future<String?> readPinRecord() async => pinRecord;

  @override
  Future<void> writePinRecord(String record) async {}
}

class _AuditPhoneAuthenticator extends Fake
    implements ParentPhoneAuthenticator {
  @override
  Future<bool> isDeviceSupported() async => false;

  @override
  Future<bool> authenticate() async => false;
}

class _GateAuditHarness extends StatelessWidget {
  const _GateAuditHarness({required this.service, required this.action});

  final ParentGateService service;
  final String action;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () {
              if (action == 'set-pin') {
                service.usePin(context);
              } else {
                service.unlock(context);
              }
            },
            child: Text('Open $action'),
          ),
        ),
      );
}

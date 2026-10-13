import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/main.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/accessibility_settings.dart';
import 'package:tinymind/services/narration_service.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/services/tts_text_helper.dart';
import 'package:tinymind/widgets/emoji_glyph.dart';

final _interjections = RegExp(
  r'\b(?:ooh|oh|hmm|woo(?:hoo)?|yay|hooray|whoa|wow|smart|uh[- ]oh|shh)\b',
  caseSensitive: false,
);

void main() {
  test('quiz lead-ins and feedback phrases avoid risky interjections', () {
    for (final phrase in [
      ...QuizPage.leadInsForTesting,
      ...QuizPage.praisesForTesting,
      ...QuizPage.oopsiesForTesting,
      'Hello, friend!',
    ]) {
      expect(_interjections.hasMatch(phrase), isFalse, reason: phrase);
    }
  });

  test('activity spokenText, teach, and hint avoid risky interjections', () {
    final failures = <String>[];
    for (final activity
        in worldCatalogs.values.expand((catalog) => catalog.activities)) {
      for (var index = 0; index < activity.questions.length; index++) {
        final question = activity.questions[index];
        for (final entry in {
          'spokenText': question.spokenText,
          'teach': question.teach,
          'hint': question.hint,
        }.entries) {
          final text = entry.value;
          if (text != null && _interjections.hasMatch(text)) {
            failures.add('${activity.id} Q${index + 1} ${entry.key}: $text');
          }
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  testWidgets('teaching screen narration is exactly its teach text',
      (tester) async {
    final activity = worldCatalogs.values
        .expand((catalog) => catalog.activities)
        .firstWhere((activity) => activity.questions.first.teach != null);
    final fakeNarration = _FakeNarrationService();
    final store = ProgressStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: QuizPage(
          activity: activity,
          store: store,
          narration: fakeNarration,
        ),
      ),
    );

    final teach = activity.questions.first.teach!;
    expect(fakeNarration.calls, hasLength(1));
    expect(fakeNarration.calls.single.text, teach);
    expect(fakeNarration.calls.single.spokenText, isNull);
    expect(
      TtsTextHelper.clean(
        fakeNarration.calls.single.spokenText ??
            fakeNarration.calls.single.text,
      ),
      TtsTextHelper.clean(teach),
    );
  });

  testWidgets('question narration starts with a configured lead-in',
      (tester) async {
    final activity = worldCatalogs.values
        .expand((catalog) => catalog.activities)
        .firstWhere((activity) => activity.questions.first.spokenText != null);
    final fakeNarration = _FakeNarrationService();
    final store = ProgressStore();
    addTearDown(store.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: QuizPage(
          activity: activity,
          store: store,
          narration: fakeNarration,
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(
      QuizPage.leadInsForTesting
          .any((lead) => fakeNarration.calls.last.spokenText!.startsWith(lead)),
      isTrue,
      reason: fakeNarration.calls.last.spokenText,
    );
  });

  testWidgets('every activity teaching screen has no spoken lead-in',
      (tester) async {
    final store = ProgressStore();
    final settings = AccessibilitySettings();
    addTearDown(store.dispose);
    addTearDown(settings.dispose);
    final activities =
        worldCatalogs.values.expand((catalog) => catalog.activities).toList();

    for (final activity in activities) {
      final fakeNarration = _FakeNarrationService();
      await tester.pumpWidget(
        AccessibilitySettingsScope(
          settings: settings,
          child: MaterialApp(
            key: ValueKey(activity.id),
            home: QuizPage(
              activity: activity,
              store: store,
              narration: fakeNarration,
            ),
          ),
        ),
      );
      final teach = activity.questions.first.teach;
      expect(teach, isNotNull, reason: activity.id);
      final spoken = fakeNarration.calls.single.text;
      expect(spoken, teach, reason: activity.id);
      expect(
        QuizPage.leadInsForTesting.any(spoken.startsWith),
        isFalse,
        reason: '${activity.id}: $spoken',
      );
    }
  });

  testWidgets('result page keeps the full-star message and updates other copy',
      (tester) async {
    final activity =
        worldCatalogs.values.expand((catalog) => catalog.activities).first;
    final world = learningModules.firstWhere(
      (world) => worldCatalogs[world.id]!.activities.contains(activity),
    );
    final store = ProgressStore();
    addTearDown(store.dispose);

    Future<void> pumpResult(int stars) => tester.pumpWidget(
          MaterialApp(
            home: ResultPage(
              world: world,
              activity: activity,
              score: stars,
              stars: stars,
              store: store,
            ),
          ),
        );

    await pumpResult(2);
    expect(
      tester.widget<EmojiText>(find.byType(EmojiText).first).text,
      'Keep going! 💪',
    );
    await pumpResult(3);
    expect(
      tester.widget<EmojiText>(find.byType(EmojiText).first).text,
      'Amazing work! 🎉',
    );
  });
}

class _FakeNarrationService implements NarrationService {
  final calls = <({String text, String? spokenText})>[];
  final _voiceVolume = ValueNotifier<double>(1.0);

  @override
  bool get voiceAvailable => true;

  @override
  double get voiceVolume => _voiceVolume.value;

  @override
  ValueNotifier<double> get voiceVolumeNotifier => _voiceVolume;

  @override
  Future<void> init() async {}

  @override
  Future<void> setVoiceVolume(double volume) async {
    _voiceVolume.value = volume.clamp(0.3, 1.0).toDouble();
  }

  @override
  Future<void> saveVoiceVolume() async {}

  @override
  Future<void> speak(String text, {String? spokenText}) async {
    calls.add((text: text, spokenText: spokenText));
  }

  @override
  Future<void> stop() async {}
}

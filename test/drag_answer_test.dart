import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/widgets/drag_answer.dart';

const _question = QuizQuestion(
  prompt: 'Choose a picture',
  options: [
    QuizOption('Blue', emoji: '🔵'),
    QuizOption('Ball', emoji: '⚽'),
    QuizOption('Apple', emoji: '🍎'),
  ],
  answerIndex: 1,
  visual: AnswerVisual.picture,
);

void main() {
  const ttsChannel = MethodChannel('flutter_tts');
  const focusChannel = MethodChannel('tinymind/speech_audio_focus');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async {
      switch (call.method) {
        case 'getEngines':
          return <String>['test-engine'];
        case 'isLanguageAvailable':
          return true;
        default:
          return 1;
      }
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(focusChannel, (call) async => true);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(focusChannel, null);
  });

  Future<void> pumpArea(
    WidgetTester tester,
    void Function(int) onDrop,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              height: 330,
              child: DragAnswerArea(
                question: _question,
                selectedIndex: null,
                answered: false,
                moduleColor: Colors.purple,
                onDrop: onDrop,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('one tap previews and selects without answering', (tester) async {
    var dropCount = 0;
    await pumpArea(tester, (_) => dropCount++);

    await tester.tap(find.byKey(const ValueKey('drag-answer-option-0')));
    await tester.pump();

    expect(dropCount, 0);
    expect(
      tester.getSize(find.byKey(const ValueKey('drag-answer-option-0'))).width,
      greaterThanOrEqualTo(64),
    );
    expect(
      find.bySemanticsLabel('Option: Blue, double tap to answer'),
      findsOneWidget,
    );
  });

  testWidgets('tapping an option twice flies it to the slot and answers once',
      (tester) async {
    var dropCount = 0;
    var droppedIndex = -1;
    await pumpArea(tester, (index) {
      dropCount++;
      droppedIndex = index;
    });
    final option = find.byKey(const ValueKey('drag-answer-option-1'));

    await tester.tap(option);
    await tester.pump();
    expect(dropCount, 0);

    await tester.tap(option);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(dropCount, 1);
    expect(droppedIndex, 1);

    await tester.tap(option);
    await tester.pump();
    expect(dropCount, 1);
  });

  testWidgets('tapping the answer slot confirms the selected option',
      (tester) async {
    var droppedIndex = -1;
    await pumpArea(tester, (index) => droppedIndex = index);
    await tester.tap(find.byKey(const ValueKey('drag-answer-option-2')));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('drag-answer-slot')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(droppedIndex, 2);
  });

  testWidgets('dragging an option to the slot still answers', (tester) async {
    var dropCount = 0;
    var droppedIndex = -1;
    await pumpArea(tester, (index) {
      dropCount++;
      droppedIndex = index;
    });
    final option = find.byKey(const ValueKey('drag-answer-option-2'));
    final slot = find.byKey(const ValueKey('drag-answer-slot'));
    final start = tester.getCenter(option);
    final end = tester.getCenter(slot);

    await tester.dragFrom(start, end - start);
    await tester.pumpAndSettle();

    expect(dropCount, 1);
    expect(droppedIndex, 2);
  });
}

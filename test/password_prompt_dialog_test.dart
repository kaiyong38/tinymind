import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/widgets/password_prompt_dialog.dart';

void main() {
  for (final label in [
    'Verify your password',
    'Confirm your account password',
  ]) {
    for (final (size, keyboard) in const [
      (Size(640, 290), 200.0),
      (Size(360, 640), 280.0),
    ]) {
      testWidgets(
          '"$label" fits at ${size.width.toInt()}x${size.height.toInt()} '
          'with a ${keyboard.toInt()} keyboard', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final harness = _DialogHarness(label);
        await harness.mount(tester);
        await harness.open(tester);
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text(label), findsOneWidget);
        final field = tester.getRect(find.byType(TextField));
        final cancel =
            tester.getRect(find.widgetWithText(TextButton, 'Cancel'));
        final proceed =
            tester.getRect(find.widgetWithText(FilledButton, 'Continue'));
        for (final rect in [field, cancel, proceed]) {
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(size.width));
          expect(rect.bottom, lessThanOrEqualTo(size.height - keyboard));
        }
        if (size.width < size.height) {
          // Narrow screens put the buttons on their own row, to the right.
          expect(proceed.top, greaterThanOrEqualTo(field.bottom));
          expect(proceed.right, greaterThan(cancel.right));
        } else {
          // Wide screens keep everything on one row.
          expect(proceed.center.dy, closeTo(field.center.dy, 12));
          expect(cancel.left, greaterThan(field.right));
        }

        await tester.enterText(find.byType(TextField), 'secret');
        await tester.tap(find.text('Continue'));
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(harness.result, 'secret');
        expect(find.text(label), findsNothing);
      });
    }
  }

  testWidgets('the dialog is at most about 560 wide', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = _DialogHarness('Verify your password');
    await harness.mount(tester);
    await harness.open(tester);

    final surface = find
        .descendant(of: find.byType(Dialog), matching: find.byType(Material))
        .first;
    expect(tester.getSize(surface).width, lessThanOrEqualTo(560));
  });

  testWidgets('the keyboard done key works like Continue', (tester) async {
    final harness = _DialogHarness('Verify your password');
    await harness.mount(tester);
    await harness.open(tester);

    await tester.enterText(find.byType(TextField), 'secret');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(harness.result, 'secret');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('Cancel closes the dialog without a password', (tester) async {
    final harness = _DialogHarness('Verify your password');
    await harness.mount(tester);
    await harness.open(tester);

    await tester.enterText(find.byType(TextField), 'secret');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(harness.closed, isTrue);
    expect(harness.result, isNull);
  });
}

class _DialogHarness {
  _DialogHarness(this.label);

  final String label;
  String? result;
  bool closed = false;

  Future<void> mount(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showDialog<String>(
                      context: context,
                      builder: (_) => PasswordPromptDialog(labelText: label),
                    );
                    closed = true;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }
}

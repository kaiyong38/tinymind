import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/main.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/widgets/large_screen_scaler.dart';

Future<void> _pumpShell(
  WidgetTester tester,
  Size size,
  double textScale,
) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => LargeScreenScaler(
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
      home: TinyMindHomeShell(store: ProgressStore()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  const sizes = [
    Size(568, 320),
    Size(640, 360),
    Size(800, 480),
    Size(1280, 800),
  ];

  for (final size in sizes) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('carousel is centred without overflow at $size x$scale',
          (tester) async {
        await _pumpShell(tester, size, scale);

        final card = tester.getRect(find.byKey(const Key('module-letters')));
        final screenCentre = tester.getRect(find.byType(Scaffold).first).center;
        expect((card.center.dx - screenCentre.dx).abs(), lessThan(2));
        expect(card.top, greaterThanOrEqualTo(0));
        expect(card.bottom, lessThanOrEqualTo(screenCentre.dy * 2));
        // Neighbours stick out past the screen edge instead of a menu column.
        expect(find.text('Learning worlds'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('only the centre world can be tapped and swiping changes it',
      (tester) async {
    await _pumpShell(tester, const Size(640, 360), 1.0);

    final second = learningModules[1];
    final secondCard = find.byKey(Key('module-${second.id}'));
    expect(secondCard, findsOneWidget);
    final ignore = find.ancestor(
      of: secondCard,
      matching: find.byType(IgnorePointer),
    );
    expect(
      tester.widgetList<IgnorePointer>(ignore).any((w) => w.ignoring),
      isTrue,
    );

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final card = tester.getRect(secondCard);
    final centre = tester.getRect(find.byType(Scaffold).first).center;
    expect((card.center.dx - centre.dx).abs(), lessThan(2));
    expect(tester.takeException(), isNull);
  });
}

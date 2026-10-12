import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/widgets/large_screen_scaler.dart';

void main() {
  testWidgets('phone layouts keep their window size and are not fitted',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(800, 360), const Size(568, 320)]) {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              LargeScreenScaler(child: child!),
          home: const _MediaQueryProbe(),
        ),
      );

      final probeContext = tester.element(find.byKey(_probeKey));
      expect(MediaQuery.sizeOf(probeContext), size);
      expect(find.byType(FittedBox), findsNothing);
    }
  });

  testWidgets('large layouts use the scaled logical canvas', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const cases = [
      (Size(1280, 800), Size(640, 400)),
      (Size(1024, 768), Size(640, 480)),
      (Size(1920, 1080), Size(1920 / 2.7, 400)),
    ];

    for (final (windowSize, expectedSize) in cases) {
      tester.view
        ..physicalSize = windowSize
        ..devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => LargeScreenScaler(child: child!),
          home: const _MediaQueryProbe(),
        ),
      );

      final probeContext = tester.element(find.byKey(_probeKey));
      final actualSize = MediaQuery.sizeOf(probeContext);
      expect(actualSize.width, closeTo(expectedSize.width, 0.01));
      expect(actualSize.height, closeTo(expectedSize.height, 0.01));
      expect(find.byType(FittedBox), findsOneWidget);
    }
  });

  testWidgets('scaled bottom-right button remains tappable at window edge',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => LargeScreenScaler(child: child!),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 100,
              height: 80,
              child: FilledButton(
                key: const ValueKey('corner-button'),
                onPressed: () => pressed = true,
                child: const Text('Tap'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(const Offset(1270, 790));
    await tester.pump();

    expect(pressed, isTrue);
  });

  testWidgets('view insets are divided by the stage scale', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1
      ..viewInsets = const FakeViewPadding(bottom: 200);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => LargeScreenScaler(child: child!),
        home: const _MediaQueryProbe(),
      ),
    );

    final probeContext = tester.element(find.byKey(_probeKey));
    expect(MediaQuery.viewInsetsOf(probeContext).bottom, closeTo(100, 0.01));
  });
}

const _probeKey = ValueKey('media-query-probe');

class _MediaQueryProbe extends StatelessWidget {
  const _MediaQueryProbe();

  @override
  Widget build(BuildContext context) => const SizedBox.expand(
        key: _probeKey,
      );
}

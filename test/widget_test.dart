import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tinymind/main.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/widgets/large_screen_scaler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ttsChannel = MethodChannel('flutter_tts');
  const focusChannel = MethodChannel('tinymind/speech_audio_focus');
  final ttsCalls = <MethodCall>[];

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ttsChannel, (call) async {
      ttsCalls.add(call);
      switch (call.method) {
        case 'getEngines':
          return <String>['test-engine'];
        case 'isLanguageAvailable':
          return true;
        default:
          return 1;
      }
    });
    messenger.setMockMethodCallHandler(focusChannel, (call) async => true);
  });

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ttsChannel, null);
    messenger.setMockMethodCallHandler(focusChannel, null);
  });

  testWidgets('TinyMind shows the learning home', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: TinyMindHomeShell(store: ProgressStore())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Learning worlds'), findsOneWidget);
    expect(find.byKey(const Key('module-letters')), findsOneWidget);
    expect(find.byTooltip('Mute music'), findsNothing);
    expect(find.byTooltip('Unmute music'), findsNothing);
    expect(find.bySemanticsLabel('Mute music'), findsNothing);
    expect(find.bySemanticsLabel('Unmute music'), findsNothing);
  });

  testWidgets('menu contains Music and Voice volume sliders', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(568, 320)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: TinyMindHomeShell(store: ProgressStore()),
      ),
    );

    await tester.tap(find.byTooltip('Menu'));
    await _pumpRoute(tester);

    expect(find.bySemanticsLabel('Voice volume'), findsOneWidget);
    expect(find.byTooltip('Mute music'), findsOneWidget);
    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders, hasLength(2));
    expect(sliders[1].min, 0.3);
    expect(sliders[1].max, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'menu blank card area and dark barrier dismiss without tab change',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: TinyMindHomeShell(store: ProgressStore())),
    );
    await tester.tap(find.byTooltip('Menu'));
    await _pumpRoute(tester);

    await tester.tap(find.byKey(const Key('home-menu-handle')));
    await _pumpRoute(tester);
    expect(find.bySemanticsLabel('Voice volume'), findsNothing);
    expect(find.text('Learning worlds'), findsOneWidget);

    await tester.tap(find.byTooltip('Menu'));
    await _pumpRoute(tester);
    await tester.tapAt(const Offset(2, 2));
    await _pumpRoute(tester);
    expect(find.bySemanticsLabel('Voice volume'), findsNothing);
    expect(find.text('Learning worlds'), findsOneWidget);
  });

  testWidgets('Stars closes the menu and Music and Voice sliders stay open',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: TinyMindHomeShell(store: ProgressStore())),
    );
    await tester.tap(find.byTooltip('Menu'));
    await _pumpRoute(tester);
    final card = tester.getRect(find.byKey(const Key('home-menu-card')));
    expect(
      card.bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
      reason: '$card',
    );
    await tester.ensureVisible(find.text('Stars'));
    await tester.tap(find.text('Stars'));
    await _pumpRoute(tester);
    expect(find.bySemanticsLabel('Voice volume'), findsNothing);

    await tester.tap(find.byTooltip('Menu'));
    await _pumpRoute(tester);
    final starsTile = find.ancestor(
      of: find.text('Stars'),
      matching: find.byType(Material),
    );
    expect(
      tester.widget<Material>(starsTile.first).color,
      const Color(0xFFFFB703).withValues(alpha: 0.22),
    );
    ttsCalls.clear();
    await tester.ensureVisible(find.byType(Slider).first);
    await tester.drag(find.byType(Slider).first, const Offset(36, 0));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Voice volume'), findsOneWidget);
    await tester.ensureVisible(find.byType(Slider).last);
    await tester.drag(find.byType(Slider).last, const Offset(-36, 0));
    await _pumpRoute(tester);
    expect(find.bySemanticsLabel('Voice volume'), findsOneWidget);
    expect(
      ttsCalls.where((call) => call.method == 'speak').last.arguments,
      'Hello, friend!',
    );
  });

  testWidgets('scaled menu dismisses from the lower-right dark area',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => LargeScreenScaler(child: child!),
        home: TinyMindHomeShell(store: ProgressStore()),
      ),
    );
    await tester.tap(find.byTooltip('Menu'));
    await _pumpRoute(tester);
    await tester.tapAt(const Offset(1275, 795));
    await _pumpRoute(tester);

    expect(find.bySemanticsLabel('Voice volume'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu layout stays contained at all target screen sizes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const sizes = [
      Size(568, 320),
      Size(640, 360),
      Size(732, 412),
      Size(1280, 800),
      Size(1024, 768),
      Size(1920, 1080),
    ];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in sizes) {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(size),
          builder: (context, child) => LargeScreenScaler(
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
          ),
          home: TinyMindHomeShell(store: ProgressStore()),
        ),
      );
      await tester.tap(find.byTooltip('Menu'));
      await _pumpRoute(tester);

      expect(
        find.bySemanticsLabel('Voice volume'),
        findsOneWidget,
        reason: '$size',
      );
      expect(tester.takeException(), isNull, reason: '$size');
      await tester.tapAt(Offset(size.width - 2, size.height - 2));
      await _pumpRoute(tester);
      expect(
        find.bySemanticsLabel('Voice volume'),
        findsNothing,
        reason: '$size',
      );
    }
  });

  testWidgets('world library groups activities and recommends one',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LibraryPage(
          world: learningModules.first,
          store: ProgressStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Letter Land'), findsOneWidget);
    expect(find.textContaining('A to I'), findsOneWidget);
    expect(find.textContaining('Try this!'), findsOneWidget);
  });
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/pages/parent_settings_page.dart';
import 'package:tinymind/services/accessibility_settings.dart';
import 'package:tinymind/services/auth_service.dart';
import 'package:tinymind/services/parent_gate_service.dart';

import 'support/fake_firebase_auth.dart';

const _tolerance = 0.01;

bool _containsRect(Rect outer, Rect inner) =>
    inner.left >= outer.left - _tolerance &&
    inner.top >= outer.top - _tolerance &&
    inner.right <= outer.right + _tolerance &&
    inner.bottom <= outer.bottom + _tolerance;

void main() {
  const sizes = [Size(851, 393), Size(568, 320), Size(1280, 800)];
  const scales = [1.0, 1.3, 1.6];
  const cardTitles = [
    'Data backup',
    'Parent lock',
    'Voice',
    'Color-friendly mode',
  ];

  testWidgets('tapping the color-friendly title or switch toggles the mode',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AccessibilitySettings();
    await tester.pumpWidget(
      AccessibilitySettingsScope(
        settings: settings,
        child: MaterialApp(
          home: ParentSettingsPage(
            gateService: ParentGateService(storage: _FakeGateStorage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initial = settings.colorFriendlyMode;

    await tester.tap(find.text('Color-friendly mode'));
    await tester.pumpAndSettle();
    expect(settings.colorFriendlyMode, !initial);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(settings.colorFriendlyMode, initial);
  });

  for (final size in sizes) {
    for (final scale in scales) {
      testWidgets(
          'settings card text stays inside its card at '
          '${size.width.toInt()}x${size.height.toInt()}, text x$scale',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final auth = AuthService(
          auth: FakeFirebaseAuth(
            user: FakeFirebaseUser(uid: 'anon', isAnonymous: true),
          ),
        );
        await tester.pumpWidget(
          AccessibilitySettingsScope(
            settings: AccessibilitySettings(),
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: ParentSettingsPage(
                gateService: ParentGateService(storage: _FakeGateStorage()),
                auth: auth,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The anonymous account shows both backup buttons.
        expect(find.text('Back up my data'), findsOneWidget);
        expect(find.text('I already have a backup (sign in)'), findsOneWidget);

        final seenTitles = <String>{};
        final failures = <String>[];

        void checkVisibleTexts() {
          for (final element in find.byType(Text).evaluate()) {
            final cardElement = find
                .ancestor(
                  of: find.byElementPredicate((e) => e == element),
                  matching: find.byType(Card),
                )
                .evaluate()
                .firstOrNull;
            if (cardElement == null) continue;
            final text = element.widget as Text;
            final label = text.data ?? text.textSpan?.toPlainText() ?? '?';
            if (cardTitles.contains(label)) seenTitles.add(label);
            final textRect = tester.getRect(
              find.byElementPredicate((e) => e == element),
            );
            final cardRect = tester.getRect(
              find.byElementPredicate((e) => e == cardElement),
            );
            if (!_containsRect(cardRect, textRect)) {
              failures.add('"$label" $textRect is outside card $cardRect');
            }
          }
        }

        // Walk the whole list so cards below the fold are checked too.
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable).first,
        );
        final position = scrollable.position;
        var offset = 0.0;
        while (true) {
          position.jumpTo(offset);
          await tester.pump();
          checkVisibleTexts();
          if (offset >= position.maxScrollExtent) break;
          offset = (offset + position.viewportDimension / 2)
              .clamp(0.0, position.maxScrollExtent);
        }

        expect(failures, isEmpty, reason: failures.join('\n'));
        expect(seenTitles, containsAll(cardTitles));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

class _FakeGateStorage implements ParentGateStorage {
  @override
  Future<ParentLockMethod?> readMethod() async => null;

  @override
  Future<String?> readPinRecord() async => null;

  @override
  Future<void> writeMethod(ParentLockMethod method) async {}

  @override
  Future<void> writePinRecord(String record) async {}
}

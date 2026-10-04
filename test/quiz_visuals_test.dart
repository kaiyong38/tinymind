import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/accessibility_settings.dart';
import 'package:tinymind/widgets/quiz_visuals.dart';

void main() {
  testWidgets('color-friendly mode toggles swatch patterns and names',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = AccessibilitySettings();
    await settings.load();

    await tester.pumpWidget(
      MaterialApp(
        home: AccessibilitySettingsScope(
          settings: settings,
          child: Scaffold(
            body: Column(
              children: [
                Builder(
                  builder: (context) => SwitchListTile(
                    title: const Text('Color-friendly mode'),
                    value: AccessibilitySettingsScope.of(context)
                        .colorFriendlyMode,
                    onChanged: settings.setColorFriendlyMode,
                  ),
                ),
                Builder(
                  builder: (context) => buildQuizVisual(
                    context,
                    const QuizOption('Red', color: Colors.red),
                    AnswerVisual.colorSwatch,
                    size: 80,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final patternFinder = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint && widget.painter is ColorPatternPainter,
    );
    expect(patternFinder, findsNothing);
    expect(find.text('Red'), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(patternFinder, findsOneWidget);
    expect(find.text('Red'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(patternFinder, findsNothing);
    expect(find.text('Red'), findsNothing);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tinymind/main.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/services/progress_store.dart';

void main() {
  testWidgets('TinyMind shows the learning home', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: TinyMindHomeShell(store: ProgressStore())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Learning worlds'), findsOneWidget);
    expect(find.byKey(const Key('module-letters')), findsOneWidget);
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

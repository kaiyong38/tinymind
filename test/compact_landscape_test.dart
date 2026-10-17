import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/main.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/pages/admin_page.dart';
import 'package:tinymind/pages/auth_pages.dart';
import 'package:tinymind/pages/child_detail_page.dart';
import 'package:tinymind/pages/parent_gate_pages.dart';
import 'package:tinymind/pages/parent_settings_page.dart';
import 'package:tinymind/services/auth_service.dart';
import 'package:tinymind/services/accessibility_settings.dart';
import 'package:tinymind/services/firestore_service.dart';
import 'package:tinymind/services/parent_gate_service.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/widgets/drag_answer.dart';

import 'support/fake_firebase_auth.dart';

void _setCompactLandscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(640, 390);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('home keeps its learning card beside the menu', (tester) async {
    _setCompactLandscape(tester);
    await tester.pumpWidget(
      MaterialApp(home: TinyMindHomeShell(store: ProgressStore())),
    );
    await tester.pump();

    final menuTapTarget = find.descendant(
      of: find.byTooltip('Menu'),
      matching: find.byType(InkWell),
    );
    final menu = tester.getRect(menuTapTarget);
    final firstWorld = tester.getRect(find.byKey(const Key('module-letters')));
    expect(menu.width, 52);
    expect(menu.height, 52);
    expect(firstWorld.left, greaterThanOrEqualTo(menu.right));
    expect(find.textContaining('/ 78 stars'), findsOneWidget);
    expect(find.textContaining('/ 26 activities'), findsOneWidget);
    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(find.text('Menu'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('world cards fit a small landscape phone', (tester) async {
    tester.view.physicalSize = const Size(320, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: TinyMindHomeShell(store: ProgressStore())),
    );
    await tester.pump();

    expect(find.text('Learning worlds'), findsOneWidget);
    expect(find.text('Letter Land'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome page fits and stretches both role buttons',
      (tester) async {
    _setCompactLandscape(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomePage(
          store: ProgressStore(),
          auth: _TestAuthService(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Add learners, view progress'), findsOneWidget);
    expect(find.text('Choose your picture to play'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result page presents all actions without scrolling',
      (tester) async {
    _setCompactLandscape(tester);
    final activity = worldCatalogs['letters']!.activities.first;
    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          world: learningModules.first,
          activity: activity,
          score: 3,
          stars: 3,
          store: ProgressStore(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Back to library'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('answer area fits its allotted compact landscape height',
      (tester) async {
    _setCompactLandscape(tester);
    const question = QuizQuestion(
      prompt: 'Pick the picture',
      options: [
        QuizOption('Apple', emoji: '🍎'),
        QuizOption('Ball', emoji: '⚽'),
        QuizOption('Cat', emoji: '🐱'),
      ],
      answerIndex: 0,
      visual: AnswerVisual.picture,
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              height: 195,
              child: DragAnswerArea(
                question: question,
                selectedIndex: null,
                answered: false,
                moduleColor: Colors.purple,
                onDrop: _ignoreAnswer,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('weekly chart fits a short landscape screen', (tester) async {
    _setCompactLandscape(tester);
    final today = DateTime.now();
    final dateKey = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 600,
              child: WeekChart(dailyStats: {
                dateKey: const [12, 9]
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('admin dashboard shows a complete child card at 640x360',
      (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_adminApp());
    await tester.pumpAndSettle();

    expect(find.text('Ava'), findsOneWidget);
    final card = tester.getRect(find.byType(Card).first);
    final appBar = tester.getRect(find.byType(AppBar));
    expect(card.top, greaterThanOrEqualTo(appBar.bottom));
    expect(card.bottom, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a child opens details with Share report',
      (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_adminApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ava'));
    await tester.pumpAndSettle();

    expect(find.byType(ChildDetailPage), findsOneWidget);
    expect(find.text('Share report'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings button opens parent settings in compact landscape',
      (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_adminApp());
    await tester.pumpAndSettle();

    final settingsButton = find.byTooltip('Settings');
    expect(tester.getSize(settingsButton), const Size(48, 48));
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    expect(find.byType(ParentSettingsPage), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final count in [1, 20]) {
    testWidgets('child picker shows the TinyMind header with $count children '
        'at 640x360', (tester) async {
      tester.view.physicalSize = const Size(640, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ChildPickerPage(
            store: ProgressStore(),
            parentUid: 'parent-1',
            auth: _TestAuthService(),
            firestore: _ManyChildrenFirestoreService(count),
            gateService: ParentGateService(
              storage: _TestGateStorage(),
              phoneAuthenticator: _TestPhoneAuthenticator(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Who is playing?'), findsNothing);
      expect(find.text('TinyMind'), findsOneWidget);
      final logo = find.byType(SvgPicture);
      expect(logo, findsOneWidget);
      expect(tester.getSize(logo).height, 40);
      final title = tester.getRect(find.text('TinyMind'));
      final manage = tester.getRect(find.text('Manage'));
      expect(title.left, greaterThanOrEqualTo(0));
      expect(manage.right, lessThanOrEqualTo(640));
      expect(title.top, greaterThanOrEqualTo(0));
    });
  }
}

class _ManyChildrenFirestoreService extends Fake implements FirestoreService {
  _ManyChildrenFirestoreService(this.count);

  final int count;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchChildren(String parentUid) =>
      Stream.value(
        _TestChildrenSnapshot([
          for (var i = 0; i < count; i++) _NamedChildDocument('child-$i'),
        ]),
      );
}

// ignore: subtype_of_sealed_class
class _NamedChildDocument extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _NamedChildDocument(this.id);

  @override
  final String id;

  @override
  Map<String, dynamic> data() => {'name': 'Kid$id', 'avatar': '🐱', 'age': 4};
}

void _ignoreAnswer(int index) {}

class _TestAuthService implements AuthService {
  @override
  User? get currentUser =>
      FakeFirebaseUser(uid: 'parent-1', isAnonymous: false);

  @override
  bool get isAnonymous => false;

  @override
  bool get hasEmailBackup => false;

  @override
  bool get hasBackup => false;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  Stream<User?> get userChanges => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _adminApp() {
  final settings = AccessibilitySettings();
  final gateService = ParentGateService(
    storage: _TestGateStorage(),
    phoneAuthenticator: _TestPhoneAuthenticator(),
  );
  return AccessibilitySettingsScope(
    settings: settings,
    child: MaterialApp(
      home: AdminPage(
        firestore: _TestFirestoreService(),
        auth: _TestAuthService(),
        gateService: gateService,
      ),
    ),
  );
}

class _TestFirestoreService extends Fake implements FirestoreService {
  final _child = _TestChildDocument();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchChildren(String parentUid) =>
      Stream.value(_TestChildrenSnapshot([_child]));

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProgress(
    String parentUid,
    String childId,
  ) =>
      Stream.value(_TestProgressSnapshot());

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
class _TestProgressSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  Map<String, dynamic>? data() => null;
}

// ignore: subtype_of_sealed_class
class _TestChildrenSnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _TestChildrenSnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

// ignore: subtype_of_sealed_class
class _TestChildDocument extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  String get id => 'child-1';

  @override
  Map<String, dynamic> data() => {
        'name': 'Ava',
        'avatar': '🐱',
        'age': 4,
        'points': 12,
        'totalQuestions': 8,
        'correctAnswers': 6,
        'activityStars': <String, int>{},
        'dailyStats': <String, dynamic>{},
      };
}

class _TestGateStorage extends Fake implements ParentGateStorage {
  @override
  Future<ParentLockMethod?> readMethod() async => null;

  @override
  Future<void> writeMethod(ParentLockMethod method) async {}

  @override
  Future<String?> readPinRecord() async => null;

  @override
  Future<void> writePinRecord(String record) async {}
}

class _TestPhoneAuthenticator extends Fake implements ParentPhoneAuthenticator {
  @override
  Future<bool> isDeviceSupported() async => false;

  @override
  Future<bool> authenticate() async => false;
}

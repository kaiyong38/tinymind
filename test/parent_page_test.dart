import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/main.dart';
import 'package:tinymind/models/activities.dart';
import 'package:tinymind/models/learning.dart';
import 'package:tinymind/models/parent_tip.dart';
import 'package:tinymind/pages/admin_page.dart';
import 'package:tinymind/services/auth_service.dart';
import 'package:tinymind/services/firestore_service.dart';
import 'package:tinymind/services/parent_gate_service.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/widgets/large_screen_scaler.dart';

import 'support/fake_firebase_auth.dart';

const _tipStart = 'Tip: start with any world. Letters is a good first one.';
const _tipDone =
    'Tip: every activity is done! Replay your favourites to earn more stars.';

Map<String, int> _stars(Iterable<String> worlds, {int? onlyFirst}) {
  final result = <String, int>{};
  for (final id in worlds) {
    final activities = worldCatalogs[id]!.activities;
    final count = onlyFirst ?? activities.length;
    for (final a in activities.take(count)) {
      result[a.id] = 3;
    }
  }
  return result;
}

void main() {
  group('parentTipFor', () {
    test('all zero suggests starting with Letters', () {
      expect(parentTipFor({}), _tipStart);
      expect(parentTipFor({'x': 0}), _tipStart);
    });

    test('picks the least complete world', () {
      final stars = _stars(['letters', 'shapes', 'colors']);
      expect(
        parentTipFor(stars),
        'Tip: try Math Town next. It has the most left to explore.',
      );
      final partial = _stars(['letters', 'numbers', 'shapes', 'colors'])
        ..remove(worldCatalogs['colors']!.activities.first.id);
      expect(
        parentTipFor(partial),
        'Tip: try Color Garden next. It has the most left to explore.',
      );
    });

    test('ties go to the first world in order', () {
      final stars = _stars(['letters', 'numbers', 'shapes', 'colors'],
          onlyFirst: 1);
      expect(
        parentTipFor(stars),
        'Tip: try ${_firstLowest(stars)} next. It has the most left to explore.',
      );
      expect(_firstLowest(stars), learningModules.first.title);
    });

    test('everything done', () {
      expect(
        parentTipFor(_stars(['letters', 'numbers', 'shapes', 'colors'])),
        _tipDone,
      );
    });
  });

  testWidgets('Grown-ups needs the PIN every time', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final gate = _Gate();
    await tester.pumpWidget(MaterialApp(
      home: TinyMindHomeShell(store: ProgressStore(), gateService: gate),
    ));
    await tester.pump();

    gate.result = false;
    await _openGrownUps(tester);
    expect(gate.unlocks, 1);
    expect(find.text('For parents'), findsNothing);
    expect(find.text('Learning worlds'), findsOneWidget);

    gate.result = true;
    await _openGrownUps(tester);
    expect(gate.unlocks, 2);
    expect(find.text('For parents'), findsOneWidget);

    // Already on Grown-ups: no second PIN.
    await _openGrownUps(tester);
    expect(gate.unlocks, 2);

    await tester.tap(find.byTooltip('Menu'));
    await _settle(tester);
    await tester.tap(find.text('Play'));
    await _settle(tester);
    await _openGrownUps(tester);
    expect(gate.unlocks, 3);
  });

  testWidgets('going to the background leaves Grown-ups', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: TinyMindHomeShell(store: ProgressStore(), gateService: _Gate()),
    ));
    await tester.pump();
    await _openGrownUps(tester);
    expect(find.text('For parents'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('For parents'), findsNothing);
    expect(find.text('Learning worlds'), findsOneWidget);
  });

  testWidgets('dashboard button skips the PIN and page text is updated',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final gate = _Gate();
    final firestore = _Firestore();
    final auth = FakeFirebaseAuth(
      user: FakeFirebaseUser(uid: 'p', isAnonymous: true),
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ParentPage(
          store: ProgressStore(),
          gateService: gate,
          auth: AuthService(auth: auth, firestore: firestore),
          firestore: firestore,
        ),
      ),
    ));
    expect(find.text('For parents'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.textContaining('educator'), findsNothing);
    expect(find.text('Weekly overview'), findsNothing);
    expect(find.textContaining('practise numbers'), findsNothing);
    expect(find.text(_tipStart), findsOneWidget);

    await tester.tap(find.text('Open learning dashboard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(gate.unlocks, 0);
    expect(find.byType(AdminPage), findsOneWidget);
    await auth.dispose();
  });

  for (final size in const [Size(568, 320), Size(800, 480), Size(1280, 800)]) {
    testWidgets('Grown-ups page fits $size', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => LargeScreenScaler(
          child: MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
        ),
        home: TinyMindHomeShell(store: ProgressStore(), gateService: _Gate()),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'home');
      await _openGrownUps(tester);
      expect(find.text('For parents'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

String _firstLowest(Map<String, int> stars) {
  var best = learningModules.first;
  var ratio = 2.0;
  for (final m in learningModules) {
    final a = worldCatalogs[m.id]!.activities;
    final r = a.where((x) => (stars[x.id] ?? 0) > 0).length / a.length;
    if (r < ratio) {
      ratio = r;
      best = m;
    }
  }
  return best.title;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _openGrownUps(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Menu'));
  await _settle(tester);
  await tester.ensureVisible(find.text('Grown-ups'));
  await tester.tap(find.text('Grown-ups'));
  await _settle(tester);
}

class _Gate extends ParentGateService {
  _Gate() : super(storage: _NoStorage());
  int unlocks = 0;
  bool result = true;

  @override
  Future<bool> unlock(BuildContext context) async {
    unlocks++;
    return result;
  }
}

class _NoStorage implements ParentGateStorage {
  @override
  Future<ParentLockMethod?> readMethod() async => null;

  @override
  Future<String?> readPinRecord() async => null;

  @override
  Future<void> writeMethod(ParentLockMethod method) async {}

  @override
  Future<void> writePinRecord(String record) async {}
}

class _Firestore extends FirestoreService {
  _Firestore() : super(firestore: _Unused());

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchChildren(String uid) =>
      Stream.value(_Snap());
}

class _Snap extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = const [];
}

class _Unused extends Fake implements FirebaseFirestore {}

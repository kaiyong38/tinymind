import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/pages/auth_pages.dart';
import 'package:tinymind/pages/edit_child_page.dart';
import 'package:tinymind/pages/parent_gate_pages.dart';
import 'package:tinymind/services/firestore_service.dart';
import 'package:tinymind/services/parent_gate_service.dart';
import 'package:tinymind/services/progress_store.dart';
import 'package:tinymind/widgets/large_screen_scaler.dart';

import 'support/fake_firebase_auth.dart';
import 'package:tinymind/services/auth_service.dart';

const _uid = 'parent-1';
const _childId = 'child-1';

void main() {
  testWidgets('editing saves both documents and keeps stars and answers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final firestore = _FakeFirestore();
    final store = ProgressStore(firestore: firestore, currentUid: () => _uid);
    await _pumpEdit(tester, store, firestore);

    await tester.enterText(find.byType(TextField), 'Nova');
    await tester.tap(find.byKey(const Key('edit-age-6')));
    await tester.tap(find.byKey(const Key('edit-avatar-🦊')));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(firestore.childDoc['name'], 'Nova');
    expect(firestore.childDoc['age'], 6);
    expect(firestore.childDoc['avatar'], '🦊');
    expect(firestore.progressDoc['childName'], 'Nova');
    expect(firestore.progressDoc['childAge'], 6);
    expect(firestore.progressDoc['avatar'], '🦊');
    expect(firestore.progressDoc['points'], 50);
    expect(firestore.progressDoc['totalQuestions'], 9);
    expect(firestore.progressDoc['activityStars'], {'a1': 3});
    expect(find.byType(EditChildPage), findsNothing);
  });

  test('profile edit fields never contain stars or answers', () {
    final fields = FirestoreService.profileEditFields(
      name: 'Nova',
      avatar: '🦊',
      age: 5,
    );
    expect(fields.child.keys, {'name', 'avatar', 'age', 'updatedAt'});
    expect(fields.progress.keys, {'childName', 'avatar', 'childAge'});
  });

  test('re-entering a child shows the new name, not the old cache', () async {
    SharedPreferences.setMockInitialValues({
      'tinymind_child_id': _childId,
      'tinymind_progress': jsonEncode({'childName': 'Old', 'points': 50}),
    });
    final firestore = _FakeFirestore()..progressDoc['childName'] = 'Nova';
    final store = ProgressStore(firestore: firestore, currentUid: () => _uid);

    await store.applyProfileEdit(
      _childId,
      name: 'Nova',
      avatar: '🦊',
      age: 6,
      parentUid: _uid,
    );
    store.configureChild(parentUid: _uid, childId: _childId);
    await store.load();

    expect(store.progress.childName, 'Nova');
    expect(store.progress.avatar, '🦊');
    expect(store.progress.childAge, 6);
    expect(store.progress.points, 50);
  });

  test('applyProfileEdit updates queued data and the selected child', () async {
    SharedPreferences.setMockInitialValues({
      'tinymind_pending_progress::$_uid::$_childId':
          jsonEncode({'childName': 'Old', 'points': 7}),
    });
    final store = ProgressStore(firestore: _FakeFirestore());
    store.configureChild(parentUid: _uid, childId: _childId);

    await store.applyProfileEdit(_childId, name: 'Nova', avatar: '🐼', age: 5);

    final pending = await store.readPendingProgress(_uid);
    expect(pending[_childId]!['childName'], 'Nova');
    expect(pending[_childId]!['points'], 7);
    expect(store.progress.childName, 'Nova');
    store.dispose();
  });

  testWidgets('invalid nickname shows the same message as the create page',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final firestore = _FakeFirestore();
    await _pumpEdit(
      tester,
      ProgressStore(firestore: firestore, currentUid: () => _uid),
      firestore,
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text(nicknameErrorText), findsOneWidget);
    expect(firestore.updates, 0);
    expect(
      find.text('Changing the age changes which activities are suggested.'),
      findsOneWidget,
    );
  });

  testWidgets('offline save is queued with a friendly message',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final firestore = _FakeFirestore()..offline = true;
    final store = ProgressStore(firestore: firestore, currentUid: () => _uid);
    await _pumpEdit(tester, store, firestore);

    await tester.enterText(find.byType(TextField), 'Nova');
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(find.text(editSavedOfflineMessage), findsOneWidget);
    final pending = await store.readPendingProgress(_uid);
    expect(pending[_childId]!['childName'], 'Nova');
    store.dispose();
    await tester.pumpAndSettle();
  });

  testWidgets('Manage opens the editor without another PIN; normal tap plays',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final firestore = _FakeFirestore();
    final gate = _CountingGate();
    final firebaseAuth = FakeFirebaseAuth(
      user: FakeFirebaseUser(uid: _uid, isAnonymous: true),
    );
    final store = ProgressStore(firestore: firestore, currentUid: () => _uid);
    await tester.pumpWidget(
      MaterialApp(
        home: ChildPickerPage(
          store: store,
          parentUid: _uid,
          firestore: firestore,
          auth: AuthService(auth: firebaseAuth, firestore: firestore),
          gateService: gate,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Manage'));
    await tester.pump();
    expect(gate.unlocks, 1);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

    await tester.tap(find.text('Old'));
    await tester.pumpAndSettle();
    expect(find.byType(EditChildPage), findsOneWidget);
    expect(gate.unlocks, 1);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Old',
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // The remove button is separate from the edit tap.
    await tester.tap(find.byKey(const Key('remove-child-Old')));
    await tester.pumpAndSettle();
    expect(find.text('Remove Old?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.tap(find.text('Old'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(EditChildPage), findsNothing);
    expect(store.childId, _childId);
    tester.takeException();
    await firebaseAuth.dispose();
  });

  for (final size in const [Size(568, 320), Size(800, 480), Size(1280, 800)]) {
    testWidgets('edit page fits $size', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final firestore = _FakeFirestore();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => LargeScreenScaler(
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
          ),
          home: EditChildPage(
            store: ProgressStore(firestore: firestore),
            firestore: firestore,
            parentUid: _uid,
            childId: _childId,
            name: 'Old',
            avatar: '🧒',
            age: 4,
          ),
        ),
      );
      await tester.pump();

      await tester.ensureVisible(find.text('Save'));
      expect(find.text('Save'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _pumpEdit(
  WidgetTester tester,
  ProgressStore store,
  _FakeFirestore firestore,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => EditChildPage(
                  store: store,
                  firestore: firestore,
                  parentUid: _uid,
                  childId: _childId,
                  name: 'Old',
                  avatar: '🧒',
                  age: 4,
                  saveTimeout: const Duration(milliseconds: 100),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

class _CountingGate extends ParentGateService {
  _CountingGate() : super(storage: _NoStorage());
  int unlocks = 0;

  @override
  Future<bool> unlock(BuildContext context) async {
    unlocks++;
    return true;
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

class _FakeFirestore extends FirestoreService {
  _FakeFirestore() : super(firestore: _UnusedFirestore());

  final childDoc = <String, dynamic>{'name': 'Old', 'avatar': '🧒', 'age': 4};
  final progressDoc = <String, dynamic>{
    'childName': 'Old',
    'avatar': '🧒',
    'childAge': 4,
    'points': 50,
    'totalQuestions': 9,
    'activityStars': {'a1': 3},
  };
  bool offline = false;
  int updates = 0;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchChildren(String uid) =>
      Stream.value(_Snapshot([_Doc(_childId, Map.of(childDoc))]));

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProgress(
          String parentUid, String childId) =>
      const Stream.empty();

  @override
  Future<Map<String, dynamic>?> loadProgress(
          String parentUid, String childId) async =>
      Map.of(progressDoc);

  @override
  Future<void> saveProgress(
          String parentUid, String childId, Map<String, dynamic> data) async =>
      offline ? Completer<void>().future : null;

  @override
  Future<void> updateChildProfile(
    String parentUid,
    String childId, {
    required String name,
    required String avatar,
    required int age,
  }) {
    updates++;
    if (offline) return Completer<void>().future;
    childDoc
      ..['name'] = name
      ..['avatar'] = avatar
      ..['age'] = age;
    progressDoc
      ..['childName'] = name
      ..['avatar'] = avatar
      ..['childAge'] = age;
    return Future.value();
  }

  @override
  Future<void> deleteChild(String parentUid, String childId) async {}
}

// ignore: subtype_of_sealed_class
class _Doc extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _Doc(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;
}

class _Snapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  _Snapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _UnusedFirestore extends Fake implements FirebaseFirestore {}

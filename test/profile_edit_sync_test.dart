import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/services/firestore_service.dart';
import 'package:tinymind/services/progress_store.dart';

const _uid = 'parent-1';
const _childId = 'child-mia';
const _pendingKey = 'tinymind_pending_progress::$_uid::$_childId';

/// The bug: a learner renamed from "Mia" (age 4) to "a" (age 6) went back to
/// "Mia" after it was opened and the parent switched learner, because an
/// older local copy of the profile was merged over the cloud and written back.
void main() {
  test('a phone with no cache for this child keeps the cloud name', () async {
    // The cache belongs to another child, so load() starts from a blank
    // UserProgress, whose default name is "Mia".
    SharedPreferences.setMockInitialValues({
      'tinymind_child_id': 'child-other',
      'tinymind_progress': jsonEncode({'childName': 'Kai', 'points': 3}),
    });
    final cloud = _CloudFirestore();
    final store = ProgressStore(firestore: cloud, currentUid: () => _uid);

    store.configureChild(parentUid: _uid, childId: _childId);
    await store.load();
    await cloud.emitProgress();

    _expectRenamed(store, cloud);
    expect(store.progress.points, 50);
    store.dispose();
  });

  test('a stale cached "Mia" does not overwrite the cloud name', () async {
    SharedPreferences.setMockInitialValues({
      'tinymind_child_id': _childId,
      'tinymind_progress':
          jsonEncode({'childName': 'Mia', 'childAge': 4, 'points': 60}),
    });
    final cloud = _CloudFirestore();
    final store = ProgressStore(firestore: cloud, currentUid: () => _uid);

    store.configureChild(parentUid: _uid, childId: _childId);
    await store.load();
    await cloud.emitProgress();

    _expectRenamed(store, cloud);
    // Stars and points still merge as before: the higher value wins.
    expect(cloud.progressDoc['points'], 60);
    store.dispose();
  });

  test('a stale queued "Mia" does not overwrite the cloud name', () async {
    SharedPreferences.setMockInitialValues({
      _pendingKey: jsonEncode({
        'childName': 'Mia',
        'childAge': 4,
        'points': 70,
        'activityStars': {'a2': 2},
      }),
    });
    final cloud = _CloudFirestore();
    final store = ProgressStore(firestore: cloud, currentUid: () => _uid);

    store.configureChild(parentUid: _uid, childId: _childId);
    await store.load();
    await cloud.emitProgress();

    _expectRenamed(store, cloud);
    expect(cloud.progressDoc['points'], 70);
    expect(cloud.progressDoc['activityStars'], {'a1': 3, 'a2': 2});
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(_pendingKey), isNull);
    store.dispose();
  });

  test('the edit arriving while "Mia" is still in memory is not undone',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cloud = _CloudFirestore()
      ..setProfile(name: 'Mia', avatar: '🧒', age: 4);
    final store = ProgressStore(firestore: cloud, currentUid: () => _uid);
    store.configureChild(parentUid: _uid, childId: _childId);
    await store.load();
    expect(store.progress.childName, 'Mia');

    // Edit learner: the cloud changes first, and its snapshot reaches the
    // store before applyProfileEdit runs.
    cloud.setProfile(name: 'a', avatar: '🦊', age: 6);
    await cloud.emitProgress();
    expect(cloud.childDoc['name'], 'a');
    expect(cloud.childDoc['age'], 6);
    await store.applyProfileEdit(
      _childId,
      name: 'a',
      avatar: '🦊',
      age: 6,
      parentUid: _uid,
    );
    await store.recordActivityResult('a3', 1);

    _expectRenamed(store, cloud);
    store.dispose();
  });

  test('an offline edit still reaches the cloud', () async {
    SharedPreferences.setMockInitialValues({
      _pendingKey: jsonEncode({'childName': 'Mia', 'points': 70}),
    });
    final cloud = _CloudFirestore()
      ..setProfile(name: 'Mia', avatar: '🧒', age: 4);
    final store = ProgressStore(firestore: cloud, currentUid: () => _uid);

    await store.applyProfileEdit(
      _childId,
      name: 'a',
      avatar: '🦊',
      age: 6,
      parentUid: _uid,
      queueForSync: true,
    );
    store.configureChild(parentUid: _uid, childId: _childId);
    // A star earned before the queued edit synced must not drop it.
    cloud.offline = true;
    await store.load();
    await store.recordActivityResult('a3', 1);
    cloud.offline = false;
    await store.syncPendingNow();
    await cloud.emitProgress();

    _expectRenamed(store, cloud);
    expect(cloud.progressDoc['points'], 70);
    expect(cloud.progressDoc['activityStars'], {'a1': 3, 'a3': 1});
    store.dispose();
  });

  test('changing the avatar on this phone still reaches the cloud', () async {
    SharedPreferences.setMockInitialValues({});
    final cloud = _CloudFirestore();
    final store = ProgressStore(firestore: cloud, currentUid: () => _uid);
    store.configureChild(parentUid: _uid, childId: _childId);
    await store.load();

    await store.setAvatar('🐼');

    expect(cloud.childDoc['avatar'], '🐼');
    expect(cloud.progressDoc['avatar'], '🐼');
    expect(cloud.childDoc['name'], 'a');
    store.dispose();
  });

  test('merging keeps the remote profile unless the local one is an edit', () {
    final remote = {'childName': 'a', 'avatar': '🦊', 'childAge': 6};
    final stale = {'childName': 'Mia', 'avatar': '🧒', 'childAge': 4};

    final merged = FirestoreService.mergeProgressData(remote, stale);
    expect(merged['childName'], 'a');
    expect(merged['avatar'], '🦊');
    expect(merged['childAge'], 6);

    final edited = FirestoreService.mergeProgressData(
      remote,
      {...stale, FirestoreService.profileEditMarker: true},
    );
    expect(edited['childName'], 'Mia');
    expect(edited['childAge'], 4);
    expect(edited.containsKey(FirestoreService.profileEditMarker), isFalse);
  });
}

void _expectRenamed(ProgressStore store, _CloudFirestore cloud) {
  expect(cloud.childDoc['name'], 'a');
  expect(cloud.childDoc['age'], 6);
  expect(cloud.progressDoc['childName'], 'a');
  expect(cloud.progressDoc['childAge'], 6);
  expect(store.progress.childName, 'a');
  expect(store.progress.childAge, 6);
}

/// Keeps the child and progress documents in memory and saves progress with
/// the same merge as the real transaction.
class _CloudFirestore extends FirestoreService {
  _CloudFirestore() : super(firestore: _UnusedFirestore());

  final childDoc = <String, dynamic>{'name': 'a', 'avatar': '🦊', 'age': 6};
  final progressDoc = <String, dynamic>{
    'childName': 'a',
    'avatar': '🦊',
    'childAge': 6,
    'points': 50,
    'totalQuestions': 9,
    'activityStars': {'a1': 3},
  };
  final _progress =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
  bool offline = false;

  void setProfile({
    required String name,
    required String avatar,
    required int age,
  }) {
    childDoc
      ..['name'] = name
      ..['avatar'] = avatar
      ..['age'] = age;
    progressDoc
      ..['childName'] = name
      ..['avatar'] = avatar
      ..['childAge'] = age;
  }

  /// Sends the current progress document to the store's listener and lets
  /// the store finish any sync it starts.
  Future<void> emitProgress() async {
    _progress.add(_DocSnapshot(Map.of(progressDoc)));
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProgress(
          String parentUid, String childId) =>
      _progress.stream;

  @override
  Future<Map<String, dynamic>?> loadProgress(
      String parentUid, String childId) async {
    if (offline) throw FirebaseException(plugin: 'cloud_firestore');
    return Map.of(progressDoc);
  }

  @override
  Future<void> saveProgress(
    String parentUid,
    String childId,
    Map<String, dynamic> data,
  ) async {
    if (offline) throw FirebaseException(plugin: 'cloud_firestore');
    final merged = FirestoreService.mergeProgressData(
      {
        ...progressDoc,
        'childName': childDoc['name'],
        'avatar': childDoc['avatar'],
        'childAge': childDoc['age'],
      },
      data,
    );
    progressDoc.addAll(merged);
    childDoc
      ..['name'] = merged['childName']
      ..['avatar'] = merged['avatar']
      ..['age'] = merged['childAge'];
  }
}

// ignore: subtype_of_sealed_class
class _DocSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _DocSnapshot(this._data);

  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic>? data() => _data;
}

class _UnusedFirestore extends Fake implements FirebaseFirestore {}

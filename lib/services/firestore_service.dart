import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _children(String parentUid) =>
      _firestore.collection('parents').doc(parentUid).collection('children');

  DocumentReference<Map<String, dynamic>> _progress(
    String parentUid,
    String childId,
  ) =>
      _children(parentUid).doc(childId).collection('progress').doc('summary');

  Future<void> saveProgress(
    String parentUid,
    String childId,
    Map<String, dynamic> data,
  ) async {
    final profile = <String, dynamic>{
      'childId': childId,
      'name': data['childName'] ?? 'Little Learner',
      'avatar': data['avatar'] ?? '🧒',
      'age': data['childAge'] ?? 4,
      'points': data['points'] ?? 0,
      'streak': data['streak'] ?? 0,
      'totalQuestions': data['totalQuestions'] ?? 0,
      'correctAnswers': data['correctAnswers'] ?? 0,
      'completedByModule': data['completedByModule'] ?? {},
      'activityStars': data['activityStars'] ?? {},
      'dailyStats': data['dailyStats'] ?? {},
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await Future.wait([
      _progress(parentUid, childId).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)),
      _children(parentUid).doc(childId).set(profile, SetOptions(merge: true)),
    ]);
  }

  Future<Map<String, dynamic>?> loadProgress(
    String parentUid,
    String childId,
  ) async {
    final snapshot = await _progress(parentUid, childId).get();
    return snapshot.data();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchChildren(String parentUid) {
    return _children(parentUid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<void> deleteChild(String parentUid, String childId) async {
    final batch = _firestore.batch()
      ..delete(_progress(parentUid, childId))
      ..delete(_children(parentUid).doc(childId));
    await batch.commit();
  }

  Future<void> deleteParentData(String parentUid) async {
    final children = await _children(parentUid).get();
    final references = <DocumentReference<Map<String, dynamic>>>[
      for (final child in children.docs) ...[
        ...((await child.reference.collection('progress').get())
            .docs
            .map((document) => document.reference)),
        child.reference,
      ],
    ];
    references.add(_firestore.collection('parents').doc(parentUid));

    for (var start = 0; start < references.length; start += 400) {
      final batch = _firestore.batch();
      for (final reference in references.skip(start).take(400)) {
        batch.delete(reference);
      }
      await batch.commit();
    }
  }

  /// One-time repair for children created before their profile started
  /// mirroring `age`/`completedByModule` onto the top-level document (the
  /// bug where an older child, e.g. one added before this fix shipped,
  /// shows no age on the dashboard while newer siblings do). Reads that
  /// child's own saved progress and, if it actually has the missing
  /// field(s), copies them up — otherwise does nothing.
  Future<void> backfillProfileFromProgress(
    String parentUid,
    String childId,
  ) async {
    final saved = await loadProgress(parentUid, childId);
    if (saved == null) return;
    final patch = <String, dynamic>{};
    if (saved['childAge'] != null) patch['age'] = saved['childAge'];
    if (saved['completedByModule'] != null) {
      patch['completedByModule'] = saved['completedByModule'];
    }
    if (saved['activityStars'] != null) {
      patch['activityStars'] = saved['activityStars'];
    }
    if (saved['dailyStats'] != null) {
      patch['dailyStats'] = saved['dailyStats'];
    }
    if (patch.isEmpty) return;
    await _children(parentUid).doc(childId).set(patch, SetOptions(merge: true));
  }
}

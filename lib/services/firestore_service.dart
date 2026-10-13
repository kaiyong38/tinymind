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
    final progress = _progress(parentUid, childId);
    final child = _children(parentUid).doc(childId);
    await _firestore.runTransaction((transaction) async {
      final remoteProgress = await transaction.get(progress);
      final remoteChild = await transaction.get(child);
      final merged = mergeProgressData(
        remoteProgress.data() ?? remoteChild.data() ?? const {},
        data,
      );
      final profile = <String, dynamic>{
        'childId': childId,
        'name': merged['childName'] ?? 'Little Learner',
        'avatar': merged['avatar'] ?? '🧒',
        'age': merged['childAge'] ?? 4,
        for (final field in const [
          'points',
          'streak',
          'totalQuestions',
          'correctAnswers',
          'completedByModule',
          'activityStars',
          'dailyStats',
          'completedQuestionIds',
          'lastPlayed',
        ])
          if (merged[field] != null) field: merged[field],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      transaction
        ..set(
          progress,
          {...merged, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        )
        ..set(child, profile, SetOptions(merge: true));
    });
  }

  static Map<String, dynamic> mergeProgressData(
    Map<String, dynamic> remote,
    Map<String, dynamic> local,
  ) {
    final merged = <String, dynamic>{...remote, ...local};
    for (final key in const [
      'points',
      'todayQuestions',
      'totalQuestions',
      'correctAnswers',
      'streak',
    ]) {
      merged[key] = _maxNumber(remote[key], local[key]);
    }
    for (final key in const [
      'completedByModule',
      'moduleAnswered',
      'moduleCorrect',
      'activityStars',
    ]) {
      final oldMap = (remote[key] as Map?) ?? const {};
      final newMap = (local[key] as Map?) ?? const {};
      merged[key] = {
        for (final id in {...oldMap.keys, ...newMap.keys})
          id: _maxNumber(oldMap[id], newMap[id]),
      };
    }
    final completed = <String>{
      ...((remote['completedQuestionIds'] as Iterable?) ?? const [])
          .whereType<String>(),
      ...((local['completedQuestionIds'] as Iterable?) ?? const [])
          .whereType<String>(),
    };
    merged['completedQuestionIds'] = completed.toList();

    final remoteDays = (remote['dailyStats'] as Map?) ?? const {};
    final localDays = (local['dailyStats'] as Map?) ?? const {};
    merged['dailyStats'] = {
      for (final day in {...remoteDays.keys, ...localDays.keys})
        day: _mergeDailyStats(remoteDays[day], localDays[day]),
    };
    final remoteDate = _dateValue(remote['lastPlayed']);
    final localDate = _dateValue(local['lastPlayed']);
    final latest = remoteDate == null
        ? localDate
        : localDate == null || remoteDate.isAfter(localDate)
            ? remoteDate
            : localDate;
    if (latest != null) merged['lastPlayed'] = latest.toIso8601String();
    return merged;
  }

  static int _maxNumber(Object? first, Object? second) {
    final a = first is num ? first.toInt() : 0;
    final b = second is num ? second.toInt() : 0;
    return a > b ? a : b;
  }

  static List<int> _mergeDailyStats(Object? first, Object? second) {
    final a = first is List ? first : const [];
    final b = second is List ? second : const [];
    return [
      _maxNumber(a.isNotEmpty ? a[0] : null, b.isNotEmpty ? b[0] : null),
      _maxNumber(a.length > 1 ? a[1] : null, b.length > 1 ? b[1] : null),
    ];
  }

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<Map<String, dynamic>?> loadProgress(
    String parentUid,
    String childId,
  ) async {
    final snapshot = await _progress(parentUid, childId).get();
    return snapshot.data();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProgress(
    String parentUid,
    String childId,
  ) =>
      _progress(parentUid, childId).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchChild(
    String parentUid,
    String childId,
  ) =>
      _children(parentUid).doc(childId).snapshots();

  Future<int> countChildren(String parentUid) async =>
      (await _children(parentUid).get()).docs.length;

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

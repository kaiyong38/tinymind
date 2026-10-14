import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/learning.dart';
import 'firestore_service.dart';

/// Holds the learner's progress. It notifies listeners whenever the progress
/// changes, so pages such as the activity library refresh their stars at once.
class ProgressStore extends ChangeNotifier {
  static const _storageKey = 'tinymind_progress';
  static const _childIdKey = 'tinymind_child_id';
  UserProgress progress = UserProgress();
  ProgressStore({
    FirestoreService? firestore,
    String? Function()? currentUid,
  })  : _firestore = firestore,
        _currentUid = currentUid;

  FirestoreService? _firestore;
  final String? Function()? _currentUid;
  String? _parentUid;
  String? _childId;
  StreamSubscription? _progressSubscription;
  Timer? _syncTimer;
  bool _syncInProgress = false;

  String? get childId => _childId;
  String? get parentUid => _parentUid;
  static const _pendingPrefix = 'tinymind_pending_progress::';

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSelectedChild() {
    final parentUid = _parentUid;
    final childId = _childId;
    if (parentUid == null || childId == null) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    _firestore ??= FirestoreService();
    return _firestore!.watchChild(parentUid, childId);
  }

  void configureChild({
    required String parentUid,
    required String childId,
  }) {
    _parentUid = parentUid;
    _childId = childId;
  }

  /// Forgets the selected child (used when the account changes) without
  /// touching any cached or queued data.
  Future<void> clearSelection() async {
    final subscription = _progressSubscription;
    _progressSubscription = null;
    _parentUid = null;
    _childId = null;
    progress = UserProgress();
    notifyListeners();
    await subscription?.cancel();
  }

  Future<void> queuePendingProgress(
    String parentUid,
    String childId,
    Map<String, dynamic> data,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _pendingKeyFor(parentUid, childId),
      jsonEncode(data),
    );
  }

  /// Queued (not yet synced) progress for [parentUid], keyed by child id.
  Future<Map<String, Map<String, dynamic>>> readPendingProgress(
    String parentUid,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final prefix = '$_pendingPrefix$parentUid::';
    final result = <String, Map<String, dynamic>>{};
    for (final key in preferences.getKeys().where(
          (key) => key.startsWith(prefix),
        )) {
      final raw = preferences.getString(key);
      if (raw == null) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          result[key.substring(prefix.length)] = decoded;
        }
      } on FormatException {
        continue;
      }
    }
    return result;
  }

  Future<void> removePendingProgress(String parentUid) async {
    final preferences = await SharedPreferences.getInstance();
    final prefix = '$_pendingPrefix$parentUid::';
    for (final key in preferences
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .toList()) {
      await preferences.remove(key);
    }
  }

  /// Runs the queued-progress sync now; anything that fails stays queued and
  /// is retried by the periodic timer.
  Future<void> syncPendingNow() async {
    await _syncPending();
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getKeys().any((key) => key.startsWith(_pendingPrefix))) {
      _syncTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
        _syncPending();
      });
    }
  }

  Future<void> clearCachedChildIfMatches(String childId) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(_childIdKey) != childId) return;
    await preferences.remove(_storageKey);
    await preferences.remove(_childIdKey);
    final parentUid = _parentUid;
    if (parentUid != null) {
      await preferences.remove(_pendingKeyFor(parentUid, childId));
    }
    if (_childId == childId) {
      _childId = null;
      progress = UserProgress();
    }
  }

  Future<void> load() async {
    await _progressSubscription?.cancel();
    final preferences = await SharedPreferences.getInstance();
    final cachedChildId = preferences.getString(_childIdKey);
    _childId ??= cachedChildId;
    // Only reuse the locally cached snapshot if it belongs to *this*
    // child. Without this check, opening a brand-new learner (or
    // switching to one with no cloud data yet) could silently inherit
    // whichever other child's stats happened to be cached last —
    // the same class of bug as two children sharing one Firestore id,
    // just showing up in the offline cache instead.
    final raw = (_childId == null || _childId == cachedChildId)
        ? preferences.getString(_storageKey)
        : null;
    if (raw != null) {
      try {
        progress =
            UserProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on FormatException {
        progress = UserProgress();
      } on TypeError {
        progress = UserProgress();
      }
    } else {
      progress = UserProgress();
    }

    if (_parentUid != null && _childId != null) {
      final queued = preferences.getString(_pendingKey);
      if (queued != null) {
        progress = UserProgress.fromJson(
          FirestoreService.mergeProgressData(
            progress.toJson(),
            jsonDecode(queued) as Map<String, dynamic>,
          ),
        );
      }
      try {
        _firestore ??= FirestoreService();
        _progressSubscription = _firestore!
            .watchProgress(_parentUid!, _childId!)
            .listen(_mergeRemoteSnapshot);
        final cloudData =
            await _firestore!.loadProgress(_parentUid!, _childId!);
        if (cloudData != null) {
          progress = UserProgress.fromJson(
            FirestoreService.mergeProgressData(
              cloudData,
              progress.toJson(),
            ),
          );
          await _saveCache(preferences);
        }
        await _syncPending();
      } on FirebaseException {
        _queueCloudSync(preferences);
      }
    }
    notifyListeners();
  }

  Future<void> recordAnswer(
    String moduleId,
    bool correct, {
    String? completedQuestionId,
  }) async {
    progress.totalQuestions++;
    progress.todayQuestions++;
    // Per-subject and per-day tallies for the parent's detail page.
    progress.moduleAnswered[moduleId] =
        (progress.moduleAnswered[moduleId] ?? 0) + 1;
    if (correct) {
      progress.moduleCorrect[moduleId] =
          (progress.moduleCorrect[moduleId] ?? 0) + 1;
    }
    final now = DateTime.now();
    final dayKey = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final today = progress.dailyStats.putIfAbsent(dayKey, () => [0, 0]);
    today[0]++;
    if (correct) today[1]++;
    if (progress.dailyStats.length > 60) {
      final keys = progress.dailyStats.keys.toList()..sort();
      for (final key in keys.take(progress.dailyStats.length - 60)) {
        progress.dailyStats.remove(key);
      }
    }
    if (correct) {
      progress.correctAnswers++;
      progress.points += 10;
      if (completedQuestionId != null) {
        progress.completedQuestionIds.add(completedQuestionId);
      }
    }
    progress.lastPlayed = now;
    await _save();
  }

  Future<void> recordActivityResult(String activityId, int stars) async {
    final previous = progress.activityStars[activityId] ?? 0;
    if (stars > previous) {
      progress.activityStars[activityId] = stars;
      await _save();
    }
  }

  /// Called once an activity is finished. Tallies the finished activity
  /// under its learning world.
  Future<void> completeModule(String moduleId) async {
    progress.completedByModule[moduleId] =
        (progress.completedByModule[moduleId] ?? 0) + 1;
    await _save();
  }

  Future<void> setAvatar(String avatar) async {
    progress.avatar = avatar;
    await _save();
  }

  Future<void> setChildProfile({
    required String name,
    required String avatar,
    int? age,
  }) async {
    progress.childName = name.trim().isEmpty ? 'Little Learner' : name.trim();
    progress.avatar = avatar;
    if (age != null) progress.childAge = age;
    await _save();
  }

  Future<void> _save() async {
    // The in-memory progress has already changed; tell the screens now rather
    // than after the (slower) disk and cloud writes.
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await _saveCache(preferences);
    final parentUid = _parentUid;
    final childId = _childId;
    if (parentUid != null && childId != null) {
      final data = progress.toJson();
      try {
        _firestore ??= FirestoreService();
        await _firestore!.saveProgress(parentUid, childId, data);
        await preferences.remove(_pendingKeyFor(parentUid, childId));
      } on FirebaseException {
        await preferences.setString(
          _pendingKeyFor(parentUid, childId),
          jsonEncode(data),
        );
        _startSyncTimer();
      }
    }
  }

  void _startSyncTimer() {
    _syncTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      _syncPending();
    });
  }

  String get _pendingKey => _pendingKeyFor(_parentUid!, _childId!);

  String _pendingKeyFor(String parentUid, String childId) =>
      '$_pendingPrefix$parentUid::$childId';

  Future<void> _queueCloudSync(SharedPreferences preferences) async {
    if (_parentUid == null || _childId == null) return;
    await preferences.setString(_pendingKey, jsonEncode(progress.toJson()));
    _syncTimer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      _syncPending();
    });
  }

  Future<void> _syncPending() async {
    if (_syncInProgress) return;
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences
        .getKeys()
        .where((key) => key.startsWith(_pendingPrefix))
        .toList();
    if (keys.isEmpty) {
      _syncTimer?.cancel();
      _syncTimer = null;
      return;
    }
    final uidProvider = _currentUid;
    final signedInUid = uidProvider != null
        ? uidProvider()
        : FirebaseAuth.instance.currentUser?.uid;
    if (signedInUid == null) return;
    final hasCurrentAccountWrites = keys.any((key) {
      final values = key.substring(_pendingPrefix.length).split('::');
      return values.length == 2 && values.first == signedInUid;
    });
    if (!hasCurrentAccountWrites) {
      _syncTimer?.cancel();
      _syncTimer = null;
      return;
    }
    _syncInProgress = true;
    try {
      for (final key in keys) {
        final values = key.substring(_pendingPrefix.length).split('::');
        if (values.length != 2) {
          throw FormatException('Invalid queued progress key: $key');
        }
        if (values[0] != signedInUid) continue;
        final pending = preferences.getString(key);
        if (pending == null) continue;
        try {
          _firestore ??= FirestoreService();
          await _firestore!.saveProgress(
            values[0],
            values[1],
            jsonDecode(pending) as Map<String, dynamic>,
          );
          await preferences.remove(key);
        } on FirebaseException {
          // Keep this entry queued while the network is unavailable.
        }
      }
    } finally {
      _syncInProgress = false;
    }
    if (!preferences
        .getKeys()
        .any((key) => key.startsWith(_pendingPrefix))) {
      _syncTimer?.cancel();
      _syncTimer = null;
    }
  }

  Future<void> _mergeRemoteSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final data = snapshot.data();
    if (data == null) return;
    final merged = FirestoreService.mergeProgressData(data, progress.toJson());
    final needsSync = jsonEncode(UserProgress.fromJson(merged).toJson()) !=
        jsonEncode(UserProgress.fromJson(data).toJson());
    progress = UserProgress.fromJson(merged);
    final preferences = await SharedPreferences.getInstance();
    await _saveCache(preferences);
    notifyListeners();
    if (needsSync) {
      await _queueCloudSync(preferences);
      await _syncPending();
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveCache(SharedPreferences preferences) async {
    await preferences.setString(_storageKey, jsonEncode(progress.toJson()));
    if (_childId != null) {
      await preferences.setString(_childIdKey, _childId!);
    }
  }
}

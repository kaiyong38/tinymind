import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
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
  ProgressStore({FirestoreService? firestore})
      : _firestore = firestore;

  FirestoreService? _firestore;
  String? _parentUid;
  String? _childId;

  String? get childId => _childId;

  void configureChild({
    required String parentUid,
    required String childId,
  }) {
    _parentUid = parentUid;
    _childId = childId;
  }

  Future<void> clearCachedChildIfMatches(String childId) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(_childIdKey) != childId) return;
    await preferences.remove(_storageKey);
    await preferences.remove(_childIdKey);
    if (_childId == childId) {
      _childId = null;
      progress = UserProgress();
    }
  }

  Future<void> load() async {
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
      try {
        _firestore ??= FirestoreService();
        final cloudData =
            await _firestore!.loadProgress(_parentUid!, _childId!);
        if (cloudData != null) {
          progress = UserProgress.fromJson(cloudData);
          await _saveCache(preferences);
        }
      } on FirebaseException {
        // The cached snapshot remains available when Firebase is offline.
      }
    }
    notifyListeners();
  }

  Future<void> recordAnswer(String moduleId, bool correct) async {
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
    }
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
    if (_parentUid != null && _childId != null) {
      try {
        _firestore ??= FirestoreService();
        await _firestore!.saveProgress(
          _parentUid!,
          _childId!,
          progress.toJson(),
        );
      } on FirebaseException {
        // Keep the local cache as the offline source of truth.
      }
    }
  }

  Future<void> _saveCache(SharedPreferences preferences) async {
    await preferences.setString(_storageKey, jsonEncode(progress.toJson()));
    if (_childId != null) {
      await preferences.setString(_childIdKey, _childId!);
    }
  }
}

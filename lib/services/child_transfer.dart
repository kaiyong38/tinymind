import 'dart:async';

import 'firestore_service.dart';
import 'progress_store.dart';

/// Copies the children saved under an anonymous account into the account the
/// parent signs in to. Existing children of the target account are never
/// touched: every copy gets a brand new child id.
class ChildTransfer {
  ChildTransfer({required this.firestore, required this.store});

  final FirestoreService firestore;
  final ProgressStore store;

  /// Reads the children (and any queued, unsynced progress) of [oldUid].
  /// Must be called while still signed in as [oldUid].
  Future<List<TransferableChild>> collect(String oldUid) async {
    final children = await firestore.readChildrenForTransfer(oldUid);
    final pending = await store.readPendingProgress(oldUid);
    final result = <TransferableChild>[];
    for (final child in children) {
      final queued = pending.remove(child.id);
      result.add(
        queued == null
            ? child
            : TransferableChild(
                child.id,
                FirestoreService.jsonSafeProgress(
                  FirestoreService.mergeProgressData(child.data, queued),
                ),
              ),
      );
    }
    // Children created offline whose cloud write never reached the server.
    for (final entry in pending.entries) {
      result.add(
        TransferableChild(
          entry.key,
          FirestoreService.jsonSafeProgress(entry.value),
        ),
      );
    }
    return result;
  }

  /// Queues one new child under [newUid] per entry of [children], then
  /// triggers the pending sync. Returns the new child ids.
  Future<List<String>> copyInto(
    String newUid,
    String oldUid,
    List<TransferableChild> children,
  ) async {
    final base = DateTime.now().microsecondsSinceEpoch;
    final newIds = <String>[];
    for (var index = 0; index < children.length; index++) {
      final childId = 'child-$newUid-$base-$index';
      await store.queuePendingProgress(newUid, childId, children[index].data);
      newIds.add(childId);
    }
    await store.removePendingProgress(oldUid);

    for (var index = 0; index < children.length; index++) {
      final data = children[index].data;
      await firestore.createChildProfile(
        newUid,
        newIds[index],
        name: (data['childName'] as String?) ?? 'Little Learner',
        avatar: (data['avatar'] as String?) ?? '🧒',
        age: (data['childAge'] as num?)?.toInt() ?? 4,
      );
    }
    try {
      await store.syncPendingNow().timeout(const Duration(seconds: 5));
    } on TimeoutException {
      // Still queued; the store retries automatically.
    }
    return newIds;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/services/progress_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('recording a new star count notifies listeners straight away', () async {
    final store = ProgressStore();
    var notifications = 0;
    store.addListener(() => notifications++);

    final pending = store.recordActivityResult('shapes_02', 3);
    // The screens are told before the disk write finishes.
    expect(notifications, 1);
    await pending;

    expect(store.progress.activityStars['shapes_02'], 3);
  });

  test('a lower or equal star count changes nothing and stays quiet', () async {
    final store = ProgressStore();
    await store.recordActivityResult('shapes_03', 3);
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.recordActivityResult('shapes_03', 2);

    expect(notifications, 0);
    expect(store.progress.activityStars['shapes_03'], 3);
  });

  test('chained activities each notify, so the library never goes stale',
      () async {
    final store = ProgressStore();
    final seen = <int>[];
    store.addListener(() => seen.add(store.progress.activityStars.length));

    await store.recordActivityResult('shapes_02', 3);
    await store.recordActivityResult('shapes_03', 3);

    expect(seen.first, 1);
    expect(seen.last, 2);
  });

  test('finishing the cloud load notifies listeners', () async {
    final store = ProgressStore();
    var notifications = 0;
    store.addListener(() => notifications++);

    await store.load();

    expect(notifications, greaterThan(0));
  });
}

// Updates the privacy policy "Last updated" date when the policy text changes.
//
// Run from anywhere: dart run tool/update_privacy_date.dart
import 'dart:io';

import 'privacy_fingerprint.dart';

void main() {
  final root = projectRootFrom(Platform.script);
  final hash = policyFingerprint(root);
  final recorded = PolicyVersion.read(root);

  if (recorded == null) {
    final current = appInfoLastUpdated(root);
    if (current == null) {
      stderr.writeln('AppInfo.privacyPolicyLastUpdated not found.');
      exitCode = 1;
      return;
    }
    PolicyVersion(hash: hash, lastUpdated: current).write(root);
    stdout
      ..writeln('Recorded the current privacy policy fingerprint '
          '(Last updated: $current).')
      ..writeln('Modified files:')
      ..writeln('  $versionPath');
    return;
  }

  if (recorded.hash == hash) {
    stdout.writeln('Privacy policy unchanged.');
    return;
  }

  final today = formatPolicyDate(DateTime.now());
  final modified = <String>[];

  void replaceIn(String path, RegExp pattern, String Function(Match) replace) {
    final file = File('${root.path}/$path');
    final before = file.readAsStringSync();
    if (!pattern.hasMatch(before)) {
      throw StateError('No "Last updated" date found in $path');
    }
    final after = before.replaceFirstMapped(pattern, replace);
    if (after != before) {
      file.writeAsStringSync(after);
      modified.add(path);
    }
  }

  for (final path in [hostedPolicyPath, docsPolicyPath]) {
    replaceIn(path, lastUpdatedHtmlPattern, (_) => 'Last updated: $today');
  }
  replaceIn(
    appInfoPath,
    lastUpdatedAppInfoPattern,
    (m) => '${m[1]}$today${m[3]}',
  );
  PolicyVersion(hash: hash, lastUpdated: today).write(root);
  modified.add(versionPath);

  stdout
    ..writeln('Privacy policy changed; Last updated set to $today.')
    ..writeln('Modified files:');
  for (final path in modified) {
    stdout.writeln('  $path');
  }
}

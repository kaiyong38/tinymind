// Shared by tool/update_privacy_date.dart and the privacy policy tests, so both
// compute the policy fingerprint from exactly the same text.
//
// The fingerprint covers:
// - public/privacy-policy.html, minus the "Last updated: ..." line;
// - every string literal in PrivacyPolicyPage.sections (the in-app policy
//   text; the "Also available online" note and the date live outside it);
// - AppInfo.supportEmail, which the in-app Contact section interpolates.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const hostedPolicyPath = 'public/privacy-policy.html';
const docsPolicyPath = 'docs/privacy-policy.html';
const policyPagePath = 'lib/pages/privacy_policy_page.dart';
const appInfoPath = 'lib/app_info.dart';
const versionPath = 'docs/privacy-policy.version.json';

final lastUpdatedHtmlPattern = RegExp(r'Last updated: [^<\r\n]*');
final lastUpdatedAppInfoPattern =
    RegExp(r"(privacyPolicyLastUpdated = ')([^']*)(')");

/// The project root, assuming the given script lives one level below it
/// (for example `tool/` or `test/`).
Directory projectRootFrom(Uri scriptUri) {
  if (scriptUri.scheme == 'file') {
    final root = File.fromUri(scriptUri).parent.parent;
    if (File('${root.path}/pubspec.yaml').existsSync()) return root;
  }
  return Directory.current;
}

String readProjectFile(Directory root, String path) =>
    File('${root.path}/$path').readAsStringSync().replaceAll('\r\n', '\n');

/// Hosted policy HTML without the "Last updated: ..." line.
String hostedPolicyText(Directory root) =>
    readProjectFile(root, hostedPolicyPath)
        .split('\n')
        .where((line) => !line.contains('Last updated:'))
        .join('\n');

/// All string literals in `PrivacyPolicyPage.sections`, joined together.
String appPolicyText(Directory root) {
  final source = readProjectFile(root, policyPagePath);
  final start = source.indexOf('static const sections');
  if (start < 0) {
    throw StateError('PrivacyPolicyPage.sections not found in $policyPagePath');
  }
  final end = source.indexOf('\n  ];', start);
  if (end < 0) {
    throw StateError('End of PrivacyPolicyPage.sections not found');
  }
  return dartStringLiterals(source.substring(start, end)).join();
}

String supportEmail(Directory root) {
  final match = RegExp(r"supportEmail = '([^']*)'")
      .firstMatch(readProjectFile(root, appInfoPath));
  if (match == null) {
    throw StateError('AppInfo.supportEmail not found in $appInfoPath');
  }
  return match.group(1)!;
}

String policyFingerprint(Directory root) {
  final text = [
    'html:',
    hostedPolicyText(root),
    'app:',
    appPolicyText(root),
    'email:',
    supportEmail(root),
  ].join('\n');
  return sha256.convert(utf8.encode(text)).toString();
}

/// Raw contents (escapes kept) of the Dart string literals in [source],
/// skipping `//` comments.
List<String> dartStringLiterals(String source) {
  final literals = <String>[];
  var i = 0;
  while (i < source.length) {
    final char = source[i];
    if (source.startsWith('//', i)) {
      final newline = source.indexOf('\n', i);
      i = newline < 0 ? source.length : newline;
    } else if (char == "'" || char == '"') {
      final triple = source.startsWith(char * 3, i);
      final quote = triple ? char * 3 : char;
      i += quote.length;
      final buffer = StringBuffer();
      while (i < source.length && !source.startsWith(quote, i)) {
        if (source[i] == r'\' && i + 1 < source.length) {
          buffer.write(source.substring(i, i + 2));
          i += 2;
        } else {
          buffer.write(source[i]);
          i++;
        }
      }
      i += quote.length;
      literals.add(buffer.toString());
    } else {
      i++;
    }
  }
  return literals;
}

class PolicyVersion {
  const PolicyVersion({required this.hash, required this.lastUpdated});

  final String hash;
  final String lastUpdated;

  static PolicyVersion? read(Directory root) {
    final file = File('${root.path}/$versionPath');
    if (!file.existsSync()) return null;
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return PolicyVersion(
      hash: json['hash'] as String,
      lastUpdated: json['lastUpdated'] as String,
    );
  }

  void write(Directory root) => File('${root.path}/$versionPath')
          .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert({
            'hash': hash,
            'lastUpdated': lastUpdated,
          })}\n');
}

String? htmlLastUpdated(Directory root, String path) => lastUpdatedHtmlPattern
    .firstMatch(readProjectFile(root, path))
    ?.group(0)
    ?.substring('Last updated: '.length)
    .trim();

String? appInfoLastUpdated(Directory root) => lastUpdatedAppInfoPattern
    .firstMatch(readProjectFile(root, appInfoPath))
    ?.group(2);

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// For example "17 October 2026".
String formatPolicyDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

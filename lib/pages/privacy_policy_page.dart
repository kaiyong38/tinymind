import 'package:flutter/material.dart';
import 'package:tinymind/app_info.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const lastUpdated = '12 October 2026';

  static const sections = <MapEntry<String, String>>[
    MapEntry(
      'What we collect',
      'TinyMind creates an anonymous Firebase Authentication account on this '
          'device by default. Backup is optional; if a parent links a Google '
          'account or an email and password, Firebase processes those details '
          '(for Google, only the account identifier and email address), but '
          'TinyMind does not store the password itself.\n\n'
          'For each child profile, we store the child’s nickname, avatar, age, '
          'points, answer statistics, activity stars and daily learning '
          'records in Cloud Firestore under the current account.\n\n'
          'On the device, SharedPreferences stores the music mute and '
          'color-friendly mode settings, the parent PIN record, and a local '
          'cache of learning progress. The PIN is required every time the '
          'parent area is opened and is not synced.',
    ),
    MapEntry(
      'What we do NOT collect',
      'TinyMind does not collect location, contacts, photos, microphone '
          'recordings or advertising IDs. The app does not use advertising or '
          'third-party analytics.',
    ),
    MapEntry(
      'How we use it',
      'We use this information only to save and show learning progress to the '
          'parent.',
    ),
    MapEntry(
      'Who can see it',
      'Only the holder of the current Firebase account can access that '
          'account’s child profiles and learning data. Google Firebase stores and '
          'processes the data on our behalf as a data processor. We do not '
          'sell or share personal data with others.\n\n'
          'Data is stored in Google Firebase’s Singapore region '
          '(asia-southeast1).\n\n'
          'TinyMind never receives or stores your fingerprint or face data; '
          'your phone\'s own security handles it. If you choose a PIN, it is '
          'kept only on this device in a scrambled form.',
    ),
    MapEntry(
      'Children’s privacy',
      'TinyMind is designed for children aged 3–6 to use at home with a '
          'parent’s supervision. The app starts with an anonymous account so '
          'children can reach the child picker without an email login. The '
          'parent area requires the device PIN on every entry.',
    ),
    MapEntry(
      'Your choices',
      'Parents can optionally link a Google account or an email as a backup '
          'while keeping the same account. Without an email backup, data is lost if the app is '
          'uninstalled or the device is changed. Signing in to an existing '
          'backup shows that account’s children. If children are saved on the '
          'phone, the parent can choose to copy them into the account as new '
          'children. The previous anonymous record stays unreachable and may '
          'remain stored until it is cleaned up.\n\n'
          'Parents can delete a child profile at any time from the parent area. '
          'Deleting the parent account also deletes its child profiles and '
          'learning data.\n\n'
          'Parents can export a learning report from the parent area. The '
          'report is generated on the phone, and parents decide whom to share '
          'it with. TinyMind does not send it automatically.',
    ),
    MapEntry(
      'Contact',
      'For privacy questions, contact us at ${AppInfo.supportEmail}.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Privacy Policy')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final section in sections) ...[
                      Text(
                        section.key,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        section.value,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 22),
                    ],
                    Text(
                      'Last updated: $lastUpdated',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

Future<void> openPrivacyPolicy(BuildContext context) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyPolicyPage(),
      ),
    );

import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const lastUpdated = '4 October 2026';
  static const contactEmail = '[YOUR CONTACT EMAIL]';

  static const sections = <MapEntry<String, String>>[
    MapEntry(
      'What we collect',
      'For a parent account, Firebase Authentication processes the parent’s '
          'email address and password. TinyMind does not store the password '
          'itself.\n\n'
          'For each child profile, we store the child’s nickname, avatar, age, '
          'points, answer statistics, activity stars and daily learning '
          'records in Cloud Firestore under the parent’s account.\n\n'
          'On the device, SharedPreferences stores the music mute and '
          'color-friendly mode settings, and the parent’s email if they choose '
          'to remember it on that device. A local cache keeps the selected '
          'child’s learning progress available offline.',
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
      'Only the parent signed in to the account can access that account’s '
          'child profiles and learning data. Google Firebase stores and '
          'processes the data on our behalf as a data processor. We do not '
          'sell or share personal data with others.',
    ),
    MapEntry(
      'Children’s privacy',
      'TinyMind is designed for children aged 3–6 to use at home with a '
          'parent’s supervision. A parent creates and manages the account.',
    ),
    MapEntry(
      'Your choices',
      'Parents can delete a child profile at any time from the parent area. '
          'Deleting the parent account also deletes its child profiles and '
          'learning data.',
    ),
    MapEntry(
      'Contact',
      'For privacy questions, contact us at $contactEmail.',
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

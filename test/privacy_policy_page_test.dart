import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/app_info.dart';
import 'package:tinymind/pages/auth_pages.dart';
import 'package:tinymind/pages/privacy_policy_page.dart';
import 'package:tinymind/services/auth_service.dart';

void main() {
  test('nickname validation rejects spaces and values over 20 characters', () {
    expect(isValidNickname('Mia'), isTrue);
    expect(isValidNickname(''), isFalse);
    expect(isValidNickname('Mia Rose'), isFalse);
    expect(isValidNickname('M' * 21), isFalse);
    expect(isValidNickname('M' * 20), isTrue);
  });

  testWidgets('privacy policy displays all required sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrivacyPolicyPage()),
    );

    for (final title in [
      'What we collect',
      'What we do NOT collect',
      'How we use it',
      'Who can see it',
      'Children’s privacy',
      'Your choices',
      'Contact',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Last updated: 12 October 2026'), findsOneWidget);
    expect(
      find.textContaining('Singapore region (asia-southeast1)'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'The report is generated on the phone, and parents decide whom to '
        'share it with. TinyMind does not send it automatically.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining(
          'anonymous account so children can reach the child picker'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Without an email backup, data is lost if the app is uninstalled',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(AppInfo.supportEmail), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  test('hosted privacy policy matches the docs copy', () {
    final docsPolicy = File('docs/privacy-policy.html').readAsStringSync();
    final hostedPolicy = File('public/privacy-policy.html').readAsStringSync();

    expect(hostedPolicy, docsPolicy);
  });

  testWidgets('forgot password shows reset guidance and support email',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          home: ForgotPasswordPage(
              auth: AuthService(auth: _UnusedFirebaseAuth()))),
    );

    expect(
      find.text(
        "We'll email a reset link. Please check your Spam folder too.",
      ),
      findsOneWidget,
    );
    expect(
      find.text('Need help? Contact ${AppInfo.supportEmail}'),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('registration requires privacy policy agreement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(auth: AuthService(auth: _UnusedFirebaseAuth())),
      ),
    );

    final register = find.text('Back up my data').last;
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();

    expect(
      find.text('Please agree to the Privacy Policy first.'),
      findsOneWidget,
    );
  });

  testWidgets('privacy policy link opens the policy from registration',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(auth: AuthService(auth: _UnusedFirebaseAuth())),
      ),
    );

    final privacyPolicyLink = find.text('Privacy Policy').last;
    await tester.ensureVisible(privacyPolicyLink);
    await tester.tap(privacyPolicyLink);
    await tester.pumpAndSettle();

    expect(find.text('What we collect'), findsOneWidget);
  });
}

class _UnusedFirebaseAuth extends Fake implements FirebaseAuth {}

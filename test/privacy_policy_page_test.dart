import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('Last updated: 4 October 2026'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('registration requires privacy policy agreement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(auth: AuthService(auth: _UnusedFirebaseAuth())),
      ),
    );

    final register = find.text('Register');
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Please agree to the Privacy Policy before creating an account.'),
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

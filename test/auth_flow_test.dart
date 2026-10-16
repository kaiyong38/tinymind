import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/pages/admin_page.dart';
import 'package:tinymind/pages/auth_pages.dart';
import 'package:tinymind/pages/parent_gate_pages.dart';
import 'package:tinymind/pages/parent_settings_page.dart';
import 'package:tinymind/services/auth_service.dart';
import 'package:tinymind/services/accessibility_settings.dart';
import 'package:tinymind/services/firestore_service.dart';
import 'package:tinymind/services/parent_gate_service.dart';
import 'package:tinymind/services/progress_store.dart';

import 'support/fake_firebase_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startup signs in anonymously and opens the child picker',
      (tester) async {
    final firebaseAuth = FakeFirebaseAuth();
    final firestore = _FakeFirestoreService();
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGatePage(
          store: ProgressStore(),
          auth: AuthService(auth: firebaseAuth),
          firestore: firestore,
        ),
      ),
    );
    await tester.pump();

    expect(firebaseAuth.anonymousSignInCalls, 1);
    expect(find.byType(ChildPickerPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await firebaseAuth.dispose();
  });

  testWidgets('failed startup shows a child-safe retry screen', (tester) async {
    final firebaseAuth = FakeFirebaseAuth(
      anonymousSignInError: FirebaseAuthException(code: 'network-request-failed'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGatePage(
          store: ProgressStore(),
          auth: AuthService(auth: firebaseAuth),
          firestore: _FakeFirestoreService(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('We could not get ready'), findsOneWidget);
    expect(find.textContaining('network'), findsNothing);
    expect(find.textContaining('email'), findsNothing);
    expect(find.textContaining('account'), findsNothing);

    firebaseAuth.anonymousSignInError = null;
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(firebaseAuth.anonymousSignInCalls, 2);
    expect(find.byType(ChildPickerPage), findsOneWidget);
    await firebaseAuth.dispose();
  });

  testWidgets('startup automatically retries after connectivity returns',
      (tester) async {
    final firebaseAuth = FakeFirebaseAuth(
      anonymousSignInError: FirebaseAuthException(code: 'network-request-failed'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StartupGatePage(
          store: ProgressStore(),
          auth: AuthService(auth: firebaseAuth),
          firestore: _FakeFirestoreService(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Retry'), findsOneWidget);

    firebaseAuth.anonymousSignInError = null;
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    expect(firebaseAuth.anonymousSignInCalls, 2);
    expect(find.byType(ChildPickerPage), findsOneWidget);
    await firebaseAuth.dispose();
  });

  testWidgets('openParentArea goes to PIN setup and never to LoginPage',
      (tester) async {
    final auth = AuthService(
      auth: FakeFirebaseAuth(
        user: FakeFirebaseUser(uid: 'anon', isAnonymous: true),
      ),
    );
    final gate = ParentGateService(storage: _FakeGateStorage());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  openParentArea(context, auth: auth, gateService: gate),
              child: const Text('For parents'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('For parents'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a PIN'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  test('linking an email keeps the anonymous uid', () async {
    final user = FakeFirebaseUser(uid: 'same-device-uid', isAnonymous: true);
    final service = AuthService(auth: FakeFirebaseAuth(user: user));

    await service.linkEmail('parent@example.com', 'a-strong-password');

    expect(user.uid, 'same-device-uid');
    expect(user.linkedCredential, isA<EmailAuthCredential>());
    expect((user.linkedCredential as EmailAuthCredential).email,
        'parent@example.com');
  });

  testWidgets('email already in use displays backup sign-in guidance',
      (tester) async {
    final user = FakeFirebaseUser(
      uid: 'anonymous',
      isAnonymous: true,
      linkError: FirebaseAuthException(code: 'email-already-in-use'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterPage(auth: AuthService(auth: FakeFirebaseAuth(user: user))),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'parent@example.com');
    await tester.enterText(fields.at(1), 'strong-password');
    await tester.enterText(fields.at(2), 'strong-password');
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    final submit = find.widgetWithText(FilledButton, 'Back up my data');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(
      find.text(
        "This email already has a backup. Use 'I already have a backup' instead.",
      ),
      findsOneWidget,
    );
  });

  group('backup sign-in with children on this phone', () {
    late FakeFirebaseAuth firebaseAuth;
    late _FakeFirestoreService firestore;
    late ProgressStore store;
    late List<String> events;

    Future<void> pumpLogin(
      WidgetTester tester, {
      String password = 'backup-password',
      bool expectDialog = true,
    }) async {
      events = [];
      SharedPreferences.setMockInitialValues({
        'tinymind_pending_progress::local-uid::child-local-pending': jsonEncode({
          'childName': 'Mei',
          'avatar': '🦊',
          'childAge': 5,
          'points': 99,
        }),
      });
      firebaseAuth = FakeFirebaseAuth(
        user: FakeFirebaseUser(uid: 'local-uid', isAnonymous: true)
          ..onDelete = () => events.add('deleteUser'),
        backupUser: FakeFirebaseUser(
          uid: 'backup-uid',
          isAnonymous: false,
          email: 'parent@example.com',
          emailProvider: true,
        ),
      );
      firestore = _FakeFirestoreService()
        ..events = events
        ..children['local-uid'] = {
          'child-a': {'childName': 'Mei', 'avatar': '🐼', 'childAge': 4, 'points': 10},
          'child-local-pending': {
            'childName': 'Mei',
            'avatar': '🦊',
            'childAge': 5,
            'points': 1,
          },
          'child-b': {'childName': 'Kai', 'avatar': '🐸', 'childAge': 6},
        }
        ..children['backup-uid'] = {
          'existing': {'childName': 'Mei', 'avatar': '🦄', 'childAge': 3},
        };
      store = _RecordingProgressStore(
        events,
        firestore: firestore,
        currentUid: () => firebaseAuth.currentUser?.uid,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            auth: _FakeAuthService(
              events,
              auth: firebaseAuth,
              firestore: firestore,
            ),
            firestore: firestore,
            store: store,
          ),
        ),
      );
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'parent@example.com');
      await tester.enterText(fields.at(1), password);
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(find.text("Bring this phone's children into your account?"),
          expectDialog ? findsOneWidget : findsNothing);
    }

    Future<void> chooseDeleteThem(WidgetTester tester) async {
      await tester.tap(find.text("Don't bring them"));
      await tester.pumpAndSettle();
      expect(find.text("Delete this phone's children?"), findsOneWidget);
      await tester.tap(find.text('Delete them'));
      await tester.pumpAndSettle();
    }

    void expectSignedInToBackup(WidgetTester tester) {
      expect(firebaseAuth.signInCalls, 1);
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(ChildPickerPage), findsOneWidget);
      expect(find.text('Welcome back! Your children are ready.'),
          findsOneWidget);
      final picker =
          tester.widget<ChildPickerPage>(find.byType(ChildPickerPage));
      expect(picker.parentUid, 'backup-uid');
      expect(firebaseAuth.anonymousSignInCalls, 0);
    }

    testWidgets('Cancel stops the sign-in', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(firebaseAuth.signInCalls, 0);
      expect(firebaseAuth.currentUser!.uid, 'local-uid');
      expect(firestore.saved, isEmpty);
      expect(firestore.deletedParents, isEmpty);
      expect(events, isEmpty);
      await firebaseAuth.dispose();
    });

    testWidgets("Don't bring them asks first, and Go back returns to the "
        'choice without deleting', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.text("Don't bring them"));
      await tester.pumpAndSettle();

      expect(find.text("Delete this phone's children?"), findsOneWidget);
      expect(
        find.text(
          'These children and their progress will be deleted and cannot be '
          'recovered. This only affects the children saved on this phone '
          "before you signed in. Your account's own children are not changed.",
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();

      expect(find.text("Delete this phone's children?"), findsNothing);
      expect(find.text("Bring this phone's children into your account?"),
          findsOneWidget);
      expect(firestore.deletedParents, isEmpty);
      expect(events, isEmpty);
      expect(firebaseAuth.signInCalls, 0);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(firebaseAuth.signInCalls, 0);
      expect(firebaseAuth.currentUser!.uid, 'local-uid');
      expect(events, isEmpty);
      await firebaseAuth.dispose();
    });

    testWidgets("Don't bring them deletes this phone's children, signs in "
        'and restarts', (tester) async {
      await pumpLogin(tester);
      await chooseDeleteThem(tester);
      final prefs = await SharedPreferences.getInstance();

      expect(events, [
        'deleteParentData:local-uid',
        'removePendingProgress:local-uid',
        'deleteUser',
        'signIn',
      ]);
      expect(firestore.deletedParents, ['local-uid']);
      expect(
        prefs.getKeys().where((k) => k.startsWith('tinymind_pending_progress')),
        isEmpty,
      );
      expect(firestore.saved, isEmpty);
      expect(firestore.created, isEmpty);
      expectSignedInToBackup(tester);
      expect(find.text('Kai'), findsNothing);
      expect(find.text('Mei'), findsOneWidget);
      await firebaseAuth.dispose();
    });

    testWidgets('a failed delete still signs in', (tester) async {
      await pumpLogin(tester);
      firestore.deleteError = true;
      (firebaseAuth.currentUser! as FakeFirebaseUser).deleteError =
          FirebaseAuthException(code: 'network-request-failed');
      await chooseDeleteThem(tester);

      expect(events, [
        'deleteParentData:local-uid',
        'removePendingProgress:local-uid',
        'deleteUser',
        'signIn',
      ]);
      expectSignedInToBackup(tester);
      await firebaseAuth.dispose();
    });

    testWidgets('an offline delete times out and still signs in',
        (tester) async {
      await pumpLogin(tester);
      firestore.deleteHangs = true;
      await tester.tap(find.text("Don't bring them"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete them'));
      await tester.pump();
      expect(firebaseAuth.signInCalls, 0);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(events, [
        'deleteParentData:local-uid',
        'removePendingProgress:local-uid',
        'deleteUser',
        'signIn',
      ]);
      expectSignedInToBackup(tester);
      await firebaseAuth.dispose();
    });

    testWidgets('a wrong password shows an error before any dialog',
        (tester) async {
      await pumpLogin(tester, password: 'wrong-password', expectDialog: false);

      expect(find.text('That email and password do not match.'),
          findsOneWidget);
      expect(find.text("Delete this phone's children?"), findsNothing);
      expect(firebaseAuth.signInCalls, 0);
      expect(firebaseAuth.currentUser!.uid, 'local-uid');
      expect(firestore.deletedParents, isEmpty);
      expect(events, isEmpty);
      await firebaseAuth.dispose();
    });

    testWidgets('Bring them queues new children, keeps duplicates, merges '
        'pending progress and clears old keys', (tester) async {
      await pumpLogin(tester);
      await tester.tap(find.text('Bring them'));
      await tester.pumpAndSettle();

      expect(firebaseAuth.signInCalls, 1);
      expect(find.byType(ChildPickerPage), findsOneWidget);
      expect(find.text('Welcome back! Your children are ready.'),
          findsOneWidget);

      final newDocs = firestore.saved['backup-uid']!;
      expect(newDocs.length, 3);
      final prefix = RegExp(r'^child-backup-uid-\d+-\d+$');
      for (final id in newDocs.keys) {
        expect(prefix.hasMatch(id), isTrue, reason: id);
        expect(id, isNot(anyOf('child-a', 'child-b', 'existing')));
      }
      final names = newDocs.values.map((d) => d['childName']).toList()..sort();
      expect(names, ['Kai', 'Mei', 'Mei']);
      // Pending anonymous progress was merged over the cloud copy.
      final pendingMei =
          newDocs.values.firstWhere((d) => d['avatar'] == '🦊');
      expect(pendingMei['points'], 99);
      // The account's own child is untouched and nothing is left queued.
      expect(firestore.saved['backup-uid']!.containsKey('existing'), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where((k) => k.startsWith('tinymind_pending_progress')),
        isEmpty,
      );
      expect(firestore.saved.containsKey('local-uid'), isFalse);
      await firebaseAuth.dispose();
    });
  });

  testWidgets('sign-in to an existing backup shows the account children',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final firebaseAuth = FakeFirebaseAuth(
      user: FakeFirebaseUser(uid: 'local-uid', isAnonymous: true),
      backupUser: FakeFirebaseUser(
        uid: 'backup-uid',
        isAnonymous: false,
        email: 'parent@example.com',
        emailProvider: true,
      ),
    );
    final firestore = _FakeFirestoreService()
      ..children['local-uid'] = {
        'x': {'childName': 'OldChild', 'avatar': '🐼', 'childAge': 4},
      }
      ..children['backup-uid'] = {
        'y': {'childName': 'AccountChild', 'avatar': '🦄', 'childAge': 4},
      };
    final store = ProgressStore(
      firestore: firestore,
      currentUid: () => firebaseAuth.currentUser?.uid,
    );
    store.configureChild(parentUid: 'local-uid', childId: 'x');
    final auth = _FakeAuthService([], auth: firebaseAuth, firestore: firestore);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(auth: auth, firestore: firestore, store: store),
      ),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'parent@example.com');
    await tester.enterText(fields.at(1), 'backup-password');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Don't bring them"));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete them'));
    await tester.pumpAndSettle();

    expect(find.byType(StartupGatePage), findsOneWidget);
    expect(find.text('AccountChild'), findsOneWidget);
    expect(find.text('OldChild'), findsNothing);
    expect(store.parentUid, isNull);
    expect(store.childId, isNull);
    await firebaseAuth.dispose();
  });

  testWidgets('clearSelection resets the store without touching other data',
      (tester) async {
    SharedPreferences.setMockInitialValues({'tinymind_progress': '{}'});
    final store = ProgressStore(firestore: _FakeFirestoreService());
    store.configureChild(parentUid: 'p', childId: 'c');
    await store.setChildProfile(name: 'Mei', avatar: '🐼', age: 4);
    expect(store.progress.childName, 'Mei');
    await store.clearSelection();
    expect(store.parentUid, isNull);
    expect(store.childId, isNull);
    expect(store.progress.childName, isNot('Mei'));
  });

  testWidgets('dashboard never shows raw Firestore errors', (tester) async {
    final auth = AuthService(
      auth: FakeFirebaseAuth(
        user: FakeFirebaseUser(uid: 'parent', isAnonymous: false),
      ),
    );
    final firestore = _FakeFirestoreService()..watchError = true;
    await tester.pumpWidget(
      MaterialApp(
        home: AdminPage(
          auth: auth,
          firestore: firestore,
          gateService: ParentGateService(storage: _FakeGateStorage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Could not load children. Please try again.'),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('permission-denied'), findsNothing);
    expect(find.textContaining('cloud_firestore'), findsNothing);
  });

  testWidgets('dashboard shows the retry state without a signed-in user',
      (tester) async {
    final auth = AuthService(auth: FakeFirebaseAuth());
    await tester.pumpWidget(
      MaterialApp(
        home: AdminPage(
          auth: auth,
          firestore: _FakeFirestoreService(),
          gateService: ParentGateService(storage: _FakeGateStorage()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Could not load children. Please try again.'),
        findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a child created offline appears without waiting for the server',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final firebaseAuth = FakeFirebaseAuth(
      user: FakeFirebaseUser(uid: 'anon', isAnonymous: true),
    );
    final firestore = _FakeFirestoreService()..offline = true;
    final store = ProgressStore(
      firestore: firestore,
      currentUid: () => firebaseAuth.currentUser?.uid,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChildPickerPage(
          store: store,
          parentUid: 'anon',
          auth: AuthService(auth: firebaseAuth, firestore: firestore),
          firestore: firestore,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Luna');
    await tester.ensureVisible(find.text('Start learning'));
    await tester.tap(find.text('Start learning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The progress transaction never completes offline, but the profile was
    // written by the plain set and the picker already shows it.
    expect(firestore.created.length, 1);
    expect(find.text('Luna'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Luna'), findsOneWidget);
    await firebaseAuth.dispose();
  });

  testWidgets('child picker does not show backup or account wording',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChildPickerPage(
          store: ProgressStore(),
          parentUid: 'child-safe-uid',
          auth: AuthService(
            auth: FakeFirebaseAuth(
              user: FakeFirebaseUser(uid: 'child-safe-uid', isAnonymous: true),
            ),
          ),
          firestore: _FakeFirestoreService(),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('backup'), findsNothing);
    expect(find.textContaining('account'), findsNothing);
    expect(find.textContaining('email'), findsNothing);
    expect(find.textContaining('login'), findsNothing);
  });

  testWidgets('anonymous dashboard reminder is dismissible and password is hidden',
      (tester) async {
    final auth = AuthService(
      auth: FakeFirebaseAuth(
        user: FakeFirebaseUser(uid: 'anon', isAnonymous: true),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AdminPage(
          auth: auth,
          firestore: _FakeFirestoreService(),
          gateService: ParentGateService(storage: _FakeGateStorage()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Your data is only on this phone. Tap to back up.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Dismiss backup reminder'));
    await tester.pump();
    expect(
      find.text('Your data is only on this phone. Tap to back up.'),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Account'));
    await tester.pump();
    expect(find.text('Change password'), findsNothing);
    expect(find.text('Delete account and all data'), findsOneWidget);
  });

  testWidgets('anonymous account menu does not offer Sign out', (tester) async {
    final auth = AuthService(
      auth: FakeFirebaseAuth(
        user: FakeFirebaseUser(uid: 'anon', isAnonymous: true),
      ),
    );
    await tester.pumpWidget(_adminApp(auth));
    await tester.tap(find.byTooltip('Account'));
    await _pumpAnimations(tester);

    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('linked account requires confirmation before signing out',
      (tester) async {
    final firebaseAuth = FakeFirebaseAuth(
      user: FakeFirebaseUser(
        uid: 'linked',
        isAnonymous: false,
        email: 'parent@example.com',
        emailProvider: true,
      ),
    );
    await tester.pumpWidget(_adminApp(AuthService(auth: firebaseAuth)));

    await tester.tap(find.byTooltip('Account'));
    await _pumpAnimations(tester);
    await tester.tap(find.text('Sign out').last);
    await _pumpAnimations(tester);

    expect(
      find.text(
        'This phone will start fresh. You can sign back in with the same '
        'account to get your children back.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await _pumpAnimations(tester);
    expect(firebaseAuth.currentUser, isNotNull);
    expect(firebaseAuth.signOutCalls, 0);

    await tester.tap(find.byTooltip('Account'));
    await _pumpAnimations(tester);
    await tester.tap(find.text('Sign out').last);
    await _pumpAnimations(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    expect(firebaseAuth.signOutCalls, 1);
    // The app restarts at a fresh startup gate, which signs in anonymously
    // and shows a picker for the NEW uid; the admin page is gone.
    expect(find.byType(AdminPage), findsNothing);
    expect(find.byType(ChildPickerPage), findsOneWidget);
    expect(firebaseAuth.anonymousSignInCalls, 1);
    expect(firebaseAuth.currentUser!.isAnonymous, isTrue);
    expect(firebaseAuth.currentUser!.uid, isNot('linked'));
    final picker = tester.widget<ChildPickerPage>(find.byType(ChildPickerPage));
    expect(picker.parentUid, firebaseAuth.currentUser!.uid);
    await firebaseAuth.dispose();
  });

  testWidgets('parent area error message does not reveal exception',
      (tester) async {
    final auth = AuthService(
      auth: FakeFirebaseAuth(
        user: FakeFirebaseUser(uid: 'anon', isAnonymous: true),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openParentArea(
                context,
                auth: auth,
                gateService: _FailingGateService(),
              ),
              child: const Text('For parents'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('For parents'));
    await tester.pumpAndSettle();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('sensitive test exception'), findsNothing);
  });

  testWidgets('settings explains optional local-only backup', (tester) async {
    final accessibility = AccessibilitySettings();
    final auth = AuthService(
      auth: FakeFirebaseAuth(
        user: FakeFirebaseUser(uid: 'anon', isAnonymous: true),
      ),
    );
    await tester.pumpWidget(
      AccessibilitySettingsScope(
        settings: accessibility,
        child: MaterialApp(
          home: ParentSettingsPage(
            gateService: ParentGateService(storage: _FakeGateStorage()),
            auth: auth,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not backed up (this device only)'), findsOneWidget);
    expect(
      find.text(
        'Without a backup, data is lost if you uninstall the app or change phone.',
      ),
      findsOneWidget,
    );
    expect(find.text('Back up my data (link email)'), findsOneWidget);
  });

  test('linkGoogle keeps the anonymous uid and reports a Google backup',
      () async {
    final user = FakeFirebaseUser(uid: 'same-device-uid', isAnonymous: true);
    final service = AuthService(
      auth: FakeFirebaseAuth(user: user),
      googleProvider: FakeGoogleCredentialProvider(),
    );
    final credential = _fakeGoogleCredential();

    final result = await service.linkGoogle(credential);

    expect(result.status, GoogleLinkStatus.linked);
    expect(user.uid, 'same-device-uid');
    expect(user.linkedCredential, same(credential));
    expect(
      AuthService(
        auth: FakeFirebaseAuth(
          user: FakeFirebaseUser(
            uid: 'g',
            isAnonymous: false,
            googleProvider: true,
          ),
        ),
      ).hasBackup,
      isTrue,
    );
  });

  test('linkGoogle returns the existing backup credential', () async {
    final existing = _fakeGoogleCredential('existing-token');
    final service = AuthService(
      auth: FakeFirebaseAuth(
        user: FakeFirebaseUser(
          uid: 'anon',
          isAnonymous: true,
          linkError: FirebaseAuthException(
            code: 'credential-already-in-use',
            credential: existing,
          ),
        ),
      ),
      googleProvider: FakeGoogleCredentialProvider(),
    );

    final result = await service.linkGoogle(_fakeGoogleCredential());

    expect(result.status, GoogleLinkStatus.alreadyHasBackup);
    expect(result.credential, same(existing));
  });

  group('Continue with Google', () {
    late FakeFirebaseAuth firebaseAuth;
    late _FakeFirestoreService firestore;
    late ProgressStore store;
    late FakeGoogleCredentialProvider google;
    late _FakeAuthService auth;
    late List<String> events;

    void setUpAccounts({
      Object? linkError,
      bool withLocalChildren = true,
    }) {
      events = [];
      SharedPreferences.setMockInitialValues({});
      firebaseAuth = FakeFirebaseAuth(
        user: FakeFirebaseUser(
          uid: 'local-uid',
          isAnonymous: true,
          linkError: linkError,
        )..onDelete = () => events.add('deleteUser'),
        backupUser: FakeFirebaseUser(
          uid: 'backup-uid',
          isAnonymous: false,
          email: 'parent@gmail.com',
          googleProvider: true,
        ),
      );
      firestore = _FakeFirestoreService()
        ..events = events
        ..children['backup-uid'] = {
          'existing': {'childName': 'Mei', 'avatar': '🦄', 'childAge': 3},
        };
      if (withLocalChildren) {
        firestore.children['local-uid'] = {
          'child-a': {'childName': 'Kai', 'avatar': '🐸', 'childAge': 6},
        };
      }
      store = _RecordingProgressStore(
        events,
        firestore: firestore,
        currentUid: () => firebaseAuth.currentUser?.uid,
      );
      google = FakeGoogleCredentialProvider(_fakeGoogleCredential());
      auth = _FakeAuthService(
        events,
        auth: firebaseAuth,
        firestore: firestore,
        googleProvider: google,
      );
    }

    Future<void> pumpRegister(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final linked = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegisterPage(
                        auth: auth,
                        firestore: firestore,
                        store: store,
                      ),
                    ),
                  );
                  events.add('registerResult:$linked');
                },
                child: const Text('Open register'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open register'));
      await tester.pumpAndSettle();
    }

    Future<void> acceptPrivacyPolicy(WidgetTester tester) async {
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
    }

    Future<void> tapGoogle(WidgetTester tester) async {
      final button = find.text('Continue with Google');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    void expectSignedInWithGoogle() {
      expect(auth.credentialSignIns, [same(google.credential)]);
      expect(firebaseAuth.credentialSignInCalls, 1);
      expect(firebaseAuth.signInCalls, 0);
      expect(auth.verifyPasswordCalls, 0);
      expect(find.byType(ChildPickerPage), findsOneWidget);
      expect(find.text('Welcome back! Your children are ready.'),
          findsOneWidget);
      expect(firebaseAuth.anonymousSignInCalls, 0);
    }

    testWidgets('needs the Privacy Policy before calling Google',
        (tester) async {
      setUpAccounts();
      await pumpRegister(tester);
      await tapGoogle(tester);

      expect(find.text('Please agree to the Privacy Policy first.'),
          findsOneWidget);
      expect(google.calls, 0);
      expect(auth.linkGoogleCalls, 0);
      expect(firebaseAuth.credentialSignInCalls, 0);
      await firebaseAuth.dispose();
    });

    testWidgets('the email path shows the same Privacy Policy prompt',
        (tester) async {
      setUpAccounts();
      await pumpRegister(tester);
      final submit = find.widgetWithText(FilledButton, 'Back up my data');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();

      expect(find.text('Please agree to the Privacy Policy first.'),
          findsOneWidget);
      await firebaseAuth.dispose();
    });

    testWidgets('cancelling Google does nothing', (tester) async {
      setUpAccounts();
      google.credential = null;
      await pumpRegister(tester);
      await acceptPrivacyPolicy(tester);
      await tapGoogle(tester);

      expect(google.calls, 1);
      expect(auth.linkGoogleCalls, 0);
      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.textContaining('Google. Please try again'), findsNothing);
      expect(find.text('Please agree to the Privacy Policy first.'),
          findsNothing);
      expect(tester.takeException(), isNull);
      expect(firebaseAuth.currentUser!.uid, 'local-uid');
      expect(events, isEmpty);
      await firebaseAuth.dispose();
    });

    testWidgets('a linked Google backup returns true', (tester) async {
      setUpAccounts();
      await pumpRegister(tester);
      await acceptPrivacyPolicy(tester);
      await tapGoogle(tester);

      expect(auth.linkGoogleCalls, 1);
      expect(find.byType(RegisterPage), findsNothing);
      expect(events, ['linkGoogle', 'registerResult:true']);
      expect(
        (firebaseAuth.currentUser! as FakeFirebaseUser).linkedCredential,
        same(google.credential),
      );
      expect(firebaseAuth.credentialSignInCalls, 0);
      await firebaseAuth.dispose();
    });

    testWidgets('a Google email that has an email backup explains what to do',
        (tester) async {
      setUpAccounts(
        linkError: FirebaseAuthException(code: 'email-already-in-use'),
      );
      await pumpRegister(tester);
      await acceptPrivacyPolicy(tester);
      await tapGoogle(tester);

      expect(
        find.text(
          "This email already has an email backup. Use 'I already have a "
          "backup' with your email and password.",
        ),
        findsOneWidget,
      );
      expect(firebaseAuth.credentialSignInCalls, 0);
      await firebaseAuth.dispose();
    });

    testWidgets('an existing Google backup can bring the children along',
        (tester) async {
      setUpAccounts(
        linkError: FirebaseAuthException(code: 'credential-already-in-use'),
      );
      await pumpRegister(tester);
      await acceptPrivacyPolicy(tester);
      await tapGoogle(tester);

      expect(find.text("Bring this phone's children into your account?"),
          findsOneWidget);
      expect(firebaseAuth.credentialSignInCalls, 0);
      await tester.tap(find.text('Bring them'));
      await tester.pumpAndSettle();

      expectSignedInWithGoogle();
      final newDocs = firestore.saved['backup-uid']!;
      expect(newDocs.length, 1);
      expect(newDocs.values.single['childName'], 'Kai');
      expect(firestore.deletedParents, isEmpty);
      await firebaseAuth.dispose();
    });

    testWidgets("an existing Google backup can delete this phone's children "
        'first', (tester) async {
      setUpAccounts(
        linkError: FirebaseAuthException(code: 'credential-already-in-use'),
      );
      await pumpRegister(tester);
      await acceptPrivacyPolicy(tester);
      await tapGoogle(tester);
      await tester.tap(find.text("Don't bring them"));
      await tester.pumpAndSettle();
      expect(find.text("Delete this phone's children?"), findsOneWidget);
      await tester.tap(find.text('Delete them'));
      await tester.pumpAndSettle();

      expect(events, [
        'linkGoogle',
        'deleteParentData:local-uid',
        'removePendingProgress:local-uid',
        'deleteUser',
        'signInWithCredential',
        // The restart removes RegisterPage without a result.
        'registerResult:null',
      ]);
      expect(firestore.saved, isEmpty);
      expectSignedInWithGoogle();
      expect(find.text('Kai'), findsNothing);
      expect(find.text('Mei'), findsOneWidget);
      await firebaseAuth.dispose();
    });

    Future<void> pumpLoginAndTapGoogle(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(auth: auth, firestore: firestore, store: store),
        ),
      );
      await tapGoogle(tester);
    }

    testWidgets('LoginPage signs in with Google and brings the children',
        (tester) async {
      setUpAccounts();
      await pumpLoginAndTapGoogle(tester);

      expect(find.text("Bring this phone's children into your account?"),
          findsOneWidget);
      await tester.tap(find.text('Bring them'));
      await tester.pumpAndSettle();

      expectSignedInWithGoogle();
      expect(auth.linkGoogleCalls, 0);
      expect(firestore.saved['backup-uid']!.length, 1);
      await firebaseAuth.dispose();
    });

    testWidgets('LoginPage with Google can delete the local children first',
        (tester) async {
      setUpAccounts();
      await pumpLoginAndTapGoogle(tester);
      await tester.tap(find.text("Don't bring them"));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete them'));
      await tester.pumpAndSettle();

      expect(events, [
        'deleteParentData:local-uid',
        'removePendingProgress:local-uid',
        'deleteUser',
        'signInWithCredential',
      ]);
      expectSignedInWithGoogle();
      await firebaseAuth.dispose();
    });

    testWidgets('LoginPage with no local children signs straight in',
        (tester) async {
      setUpAccounts(withLocalChildren: false);
      await pumpLoginAndTapGoogle(tester);

      expect(find.text("Bring this phone's children into your account?"),
          findsNothing);
      expectSignedInWithGoogle();
      await firebaseAuth.dispose();
    });

    testWidgets('LoginPage ignores a cancelled Google sign-in',
        (tester) async {
      setUpAccounts();
      google.credential = null;
      await pumpLoginAndTapGoogle(tester);

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text("Bring this phone's children into your account?"),
          findsNothing);
      expect(firebaseAuth.credentialSignInCalls, 0);
      expect(firebaseAuth.currentUser!.uid, 'local-uid');
      expect(events, isEmpty);
      await firebaseAuth.dispose();
    });
  });

  group('Google account menu', () {
    late FakeFirebaseUser user;
    late FakeGoogleCredentialProvider google;
    late _FakeAuthService auth;

    Future<void> pumpAdmin(WidgetTester tester) async {
      user = FakeFirebaseUser(
        uid: 'google-uid',
        isAnonymous: false,
        email: 'parent@gmail.com',
        googleProvider: true,
      );
      google = FakeGoogleCredentialProvider(_fakeGoogleCredential());
      auth = _FakeAuthService(
        [],
        auth: FakeFirebaseAuth(user: user),
        googleProvider: google,
      );
      await tester.pumpWidget(_adminApp(auth));
      await tester.tap(find.byTooltip('Account'));
      await _pumpAnimations(tester);
    }

    testWidgets('has no Change password', (tester) async {
      await pumpAdmin(tester);

      expect(find.text('Change password'), findsNothing);
      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('I already have a backup (sign in)'), findsNothing);
    });

    testWidgets('delete account checks Google instead of a password',
        (tester) async {
      await pumpAdmin(tester);
      await tester.tap(find.text('Delete account and all data'));
      await _pumpAnimations(tester);

      expect(find.text('Verify your password'), findsNothing);
      expect(auth.reauthenticateWithGoogleCalls, 1);
      expect(user.reauthenticationCalls, 1);
      expect(find.text('Delete account and all data?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _pumpAnimations(tester);
      expect(user.deleteCalls, 0);
    });

    testWidgets('a cancelled Google check stops the delete', (tester) async {
      await pumpAdmin(tester);
      google.credential = null;
      await tester.tap(find.text('Delete account and all data'));
      await _pumpAnimations(tester);

      expect(find.text('Verify your password'), findsNothing);
      expect(auth.reauthenticateWithGoogleCalls, 1);
      expect(user.reauthenticationCalls, 0);
      expect(find.text('Google sign-in was cancelled.'), findsOneWidget);
      expect(find.text('Delete account and all data?'), findsNothing);
      expect(user.deleteCalls, 0);
    });
  });
}

AuthCredential _fakeGoogleCredential([String idToken = 'fake-id-token']) =>
    GoogleAuthProvider.credential(idToken: idToken);

class FakeGoogleCredentialProvider implements GoogleCredentialProvider {
  FakeGoogleCredentialProvider([this.credential]);

  /// What the next pick returns; null acts like the parent cancelling.
  AuthCredential? credential;
  int calls = 0;

  @override
  Future<AuthCredential?> getCredential() async {
    calls++;
    return credential;
  }
}

Widget _adminApp(AuthService auth) => MaterialApp(
      home: AdminPage(
        auth: auth,
        firestore: _FakeFirestoreService(),
        gateService: ParentGateService(storage: _FakeGateStorage()),
      ),
    );

Future<void> _pumpAnimations(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

class _FailingGateService extends ParentGateService {
  _FailingGateService() : super(storage: _FakeGateStorage());

  @override
  Future<bool> unlock(BuildContext context) async {
    throw StateError('sensitive test exception');
  }
}

class _FakeFirestoreService extends FirestoreService {
  _FakeFirestoreService() : super(firestore: _UnusedFirestore());

  // uid -> childId -> data using progress-map keys (childName, avatar, ...).
  final Map<String, Map<String, Map<String, dynamic>>> children = {};
  final Map<String, Map<String, Map<String, dynamic>>> saved = {};
  final List<String> created = [];
  final _changes = StreamController<void>.broadcast(sync: true);
  int deleteParentDataCalls = 0;
  bool watchError = false;
  bool offline = false;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchChildren(String parentUid) {
    if (watchError) {
      return Stream.error(StateError('[cloud_firestore/permission-denied] x'));
    }
    return Stream.multi((controller) {
      QuerySnapshot<Map<String, dynamic>> snapshot() => _FakeChildrenSnapshot([
            for (final entry in (children[parentUid] ?? {}).entries)
              _FakeChildDoc(entry.key, {
                'name': entry.value['childName'] ?? entry.value['name'],
                'avatar': entry.value['avatar'],
                'age': entry.value['childAge'] ?? entry.value['age'],
              }),
          ]);
      controller.add(snapshot());
      final sub = _changes.stream.listen((_) => controller.add(snapshot()));
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProgress(
          String parentUid, String childId) =>
      const Stream.empty();

  @override
  Future<Map<String, dynamic>?> loadProgress(
          String parentUid, String childId) async =>
      null;

  @override
  Future<int> countChildren(String parentUid) async =>
      children[parentUid]?.length ?? 0;

  @override
  Future<List<TransferableChild>> readChildrenForTransfer(
          String parentUid) async =>
      [
        for (final entry in (children[parentUid] ?? {}).entries)
          TransferableChild(entry.key, Map<String, dynamic>.from(entry.value)),
      ];

  @override
  Future<void> createChildProfile(
    String parentUid,
    String childId, {
    required String name,
    required String avatar,
    required int age,
  }) async {
    created.add(childId);
    (children[parentUid] ??= {})[childId] = {
      'childName': name,
      'avatar': avatar,
      'childAge': age,
    };
    _changes.add(null);
  }

  @override
  Future<void> saveProgress(
    String parentUid,
    String childId,
    Map<String, dynamic> data,
  ) async {
    // Offline transactions never complete.
    if (offline) return Completer<void>().future;
    (saved[parentUid] ??= {})[childId] = data;
  }

  @override
  Future<void> deleteParentData(String parentUid) async {
    deleteParentDataCalls++;
    deletedParents.add(parentUid);
    events.add('deleteParentData:$parentUid');
    // Offline batch commits never complete.
    if (deleteHangs) return Completer<void>().future;
    if (deleteError) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
  }

  final List<String> deletedParents = [];
  List<String> events = [];
  bool deleteError = false;
  bool deleteHangs = false;
}

class _FakeAuthService extends AuthService {
  _FakeAuthService(
    this.events, {
    super.auth,
    super.firestore,
    super.googleProvider,
  });

  static const correctPassword = 'backup-password';
  final List<String> events;
  int verifyPasswordCalls = 0;
  int linkGoogleCalls = 0;
  int reauthenticateWithGoogleCalls = 0;
  final List<AuthCredential> credentialSignIns = [];

  @override
  Future<GoogleLinkResult> linkGoogle(AuthCredential credential) {
    linkGoogleCalls++;
    events.add('linkGoogle');
    return super.linkGoogle(credential);
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) {
    credentialSignIns.add(credential);
    events.add('signInWithCredential');
    return super.signInWithCredential(credential);
  }

  @override
  Future<void> reauthenticateWithGoogle() {
    reauthenticateWithGoogleCalls++;
    return super.reauthenticateWithGoogle();
  }

  @override
  Future<void> verifyPassword(String email, String password) async {
    verifyPasswordCalls++;
    if (password != correctPassword) {
      throw FirebaseAuthException(code: 'wrong-password');
    }
  }

  @override
  Future<UserCredential> signIn(String email, String password) {
    events.add('signIn');
    return super.signIn(email, password);
  }
}

class _RecordingProgressStore extends ProgressStore {
  _RecordingProgressStore(this.events, {super.firestore, super.currentUid});

  final List<String> events;

  @override
  Future<void> removePendingProgress(String parentUid) async {
    events.add('removePendingProgress:$parentUid');
    await super.removePendingProgress(parentUid);
  }
}

// ignore: subtype_of_sealed_class
class _FakeChildDoc extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _FakeChildDoc(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;
}

class _FakeChildrenSnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  _FakeChildrenSnapshot(this.docs);

  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

class _UnusedFirestore extends Fake implements FirebaseFirestore {}

class _FakeGateStorage implements ParentGateStorage {
  String? pinRecord;

  @override
  Future<ParentLockMethod?> readMethod() async => null;

  @override
  Future<String?> readPinRecord() async => pinRecord;

  @override
  Future<void> writeMethod(ParentLockMethod method) async {}

  @override
  Future<void> writePinRecord(String record) async {
    pinRecord = record;
  }
}

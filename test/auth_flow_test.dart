import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('Who is playing?'), findsNothing);
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

  testWidgets('backup sign-in warns when local child profiles exist',
      (tester) async {
    final anonymous =
        FakeFirebaseUser(uid: 'local-uid', isAnonymous: true);
    final existingBackup = FakeFirebaseUser(
      uid: 'backup-uid',
      isAnonymous: false,
      email: 'parent@example.com',
      emailProvider: true,
    );
    final firebaseAuth = FakeFirebaseAuth(
      user: anonymous,
      backupUser: existingBackup,
    );
    final firestore = _FakeFirestoreService(childCount: 1);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          auth: AuthService(auth: firebaseAuth, firestore: firestore),
          firestore: firestore,
        ),
      ),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'parent@example.com');
    await tester.enterText(fields.at(1), 'backup-password');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Children on this device will not be shown after signing in. '
        'They are not deleted.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(firebaseAuth.signInCalls, 1);
    expect(firestore.deleteParentDataCalls, 0);
    expect(firebaseAuth.currentUser!.uid, 'backup-uid');
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
          parentUid: 'anon',
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
        'This phone will start fresh. Sign in again with your email to get '
        'your children back.',
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
    await _pumpAnimations(tester);

    expect(firebaseAuth.currentUser, isNull);
    expect(firebaseAuth.signOutCalls, 1);
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
}

Widget _adminApp(AuthService auth) => MaterialApp(
      home: AdminPage(
        parentUid: 'parent',
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
  _FakeFirestoreService({this.childCount = 0})
      : super(firestore: _UnusedFirestore());

  final int childCount;
  int deleteParentDataCalls = 0;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchChildren(String parentUid) =>
      const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();

  @override
  Future<int> countChildren(String parentUid) async => childCount;

  @override
  Future<void> deleteParentData(String parentUid) async {
    deleteParentDataCalls++;
  }
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

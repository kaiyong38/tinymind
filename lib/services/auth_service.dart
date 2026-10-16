import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirestoreService? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore;
  final FirebaseAuth _auth;
  final FirestoreService? _firestore;

  User? get currentUser => _auth.currentUser;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;
  bool get hasEmailBackup =>
      currentUser?.providerData
          .any((provider) => provider.providerId == 'password') ??
      false;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// True while LoginPage swaps accounts. Deleting the anonymous user signs
  /// out for a moment, and the startup gate must not sign in anonymously then.
  bool isSwitchingAccount = false;

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  /// Checks an email and password without touching the current sign-in.
  /// It signs in on a throwaway second Firebase app, then removes that app.
  /// Throws the original [FirebaseAuthException] when the details are wrong.
  Future<void> verifyPassword(String email, String password) async {
    const name = 'tinymind_verify';
    final existing = Firebase.apps.where((app) => app.name == name);
    final app = existing.isNotEmpty
        ? existing.first
        : await Firebase.initializeApp(
            name: name,
            options: Firebase.app().options,
          );
    try {
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await auth.signOut();
    } finally {
      await app.delete();
    }
  }

  Future<UserCredential> linkEmail(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw FirebaseAuthException(
        code: 'not-anonymous',
        message: 'An anonymous account is required to link an email.',
      );
    }
    return user.linkWithCredential(
      EmailAuthProvider.credential(email: email.trim(), password: password),
    );
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();

  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null ||
        user.email == null ||
        !user.providerData
            .any((provider) => provider.providerId == 'password')) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to delete your account.',
      );
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
  }

  Future<void> deleteAccountAndData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to delete your account.',
      );
    }
    await (_firestore ?? FirestoreService()).deleteParentData(user.uid);
    await user.delete();
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('tinymind_progress');
    await preferences.remove('tinymind_child_id');
    await preferences.remove('tinymind_remembered_email');
    final pendingKeys = preferences
        .getKeys()
        .where(
          (key) => key.startsWith('tinymind_pending_progress::${user.uid}::'),
        )
        .toList();
    for (final key in pendingKeys) {
      await preferences.remove(key);
    }
  }

  /// Changes the signed-in parent's password. Firebase requires a recent
  /// sign-in before a password change, so we re-authenticate with their
  /// current password first.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null ||
        user.email == null ||
        !user.providerData
            .any((provider) => provider.providerId == 'password')) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to change your password.',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}

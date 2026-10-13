import 'package:firebase_auth/firebase_auth.dart';
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

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

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

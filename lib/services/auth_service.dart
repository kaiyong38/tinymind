import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_info.dart';
import 'firestore_service.dart';

/// Asks the parent to pick a Google account and returns a Firebase
/// credential for it, or null when they cancel.
abstract interface class GoogleCredentialProvider {
  Future<AuthCredential?> getCredential();
}

class GoogleSignInCredentialProvider implements GoogleCredentialProvider {
  static Future<void>? _initialized;

  @override
  Future<AuthCredential?> getCredential() async {
    final signIn = GoogleSignIn.instance;
    // initialize must run exactly once; allow a retry if it failed.
    try {
      await (_initialized ??=
          signIn.initialize(serverClientId: AppInfo.googleServerClientId));
    } catch (_) {
      _initialized = null;
      rethrow;
    }
    final GoogleSignInAccount account;
    try {
      account = await signIn.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google did not return an ID token.',
      );
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }
}

enum GoogleLinkStatus { linked, alreadyHasBackup }

class GoogleLinkResult {
  const GoogleLinkResult.linked()
      : status = GoogleLinkStatus.linked,
        credential = null;
  const GoogleLinkResult.alreadyHasBackup(this.credential)
      : status = GoogleLinkStatus.alreadyHasBackup;

  final GoogleLinkStatus status;

  /// For [GoogleLinkStatus.alreadyHasBackup]: signs in to that backup.
  final AuthCredential? credential;
}

/// The email and password are right, but the email has not been verified.
class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException([
    this.message = 'This email has not been verified yet.',
  ]);

  final String message;

  @override
  String toString() => 'EmailNotVerifiedException: $message';
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirestoreService? firestore,
    GoogleCredentialProvider? googleProvider,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore,
        _googleProvider = googleProvider ?? GoogleSignInCredentialProvider();
  final FirebaseAuth _auth;
  final FirestoreService? _firestore;
  final GoogleCredentialProvider _googleProvider;

  User? get currentUser => _auth.currentUser;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;
  bool get hasEmailBackup =>
      currentUser?.providerData
          .any((provider) => provider.providerId == 'password') ??
      false;
  bool get hasGoogleBackup =>
      currentUser?.providerData
          .any((provider) => provider.providerId == 'google.com') ??
      false;
  bool get hasBackup => hasEmailBackup || hasGoogleBackup;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// True while LoginPage swaps accounts. Deleting the anonymous user signs
  /// out for a moment, and the startup gate must not sign in anonymously then.
  bool isSwitchingAccount = false;

  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<UserCredential> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  /// Checks an email and password without touching the current sign-in.
  /// It signs in on a throwaway second Firebase app, then removes that app.
  /// Throws the original [FirebaseAuthException] when the details are wrong,
  /// and [EmailNotVerifiedException] when the email is not verified yet.
  Future<void> verifyPassword(String email, String password) async {
    final verified = await _withTemporaryAuth((auth) async {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user?.emailVerified ?? false;
    });
    if (!verified) throw const EmailNotVerifiedException();
  }

  /// Sends the verification email again for an account the parent cannot
  /// sign in to yet, using the same throwaway Firebase app as
  /// [verifyPassword].
  Future<void> resendVerificationFor(String email, String password) =>
      _withTemporaryAuth((auth) async {
        final credential = await auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        await credential.user?.sendEmailVerification();
      });

  /// Runs [action] on a throwaway second Firebase app, then signs out and
  /// removes that app even when [action] fails.
  Future<T> _withTemporaryAuth<T>(
    Future<T> Function(FirebaseAuth auth) action,
  ) async {
    const name = 'tinymind_verify';
    final existing = Firebase.apps.where((app) => app.name == name);
    final app = existing.isNotEmpty
        ? existing.first
        : await Firebase.initializeApp(
            name: name,
            options: Firebase.app().options,
          );
    final auth = FirebaseAuth.instanceFor(app: app);
    try {
      return await action(auth);
    } finally {
      try {
        await auth.signOut();
      } catch (_) {}
      await app.delete();
    }
  }

  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  Future<void> sendVerificationEmail() async {
    final user = currentUser;
    if (user == null || user.emailVerified) return;
    await user.sendEmailVerification();
  }

  /// Reloads the user from Firebase so a link opened in the email shows up.
  Future<bool> refreshEmailVerified() async {
    await currentUser?.reload();
    return currentUser?.emailVerified ?? false;
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

  Future<AuthCredential?> pickGoogleCredential() =>
      _googleProvider.getCredential();

  /// Links a Google account to this phone's anonymous account, keeping the
  /// uid. If that Google account already has its own backup, returns
  /// [GoogleLinkResult.alreadyHasBackup] with a credential to sign in to it.
  Future<GoogleLinkResult> linkGoogle(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      throw FirebaseAuthException(
        code: 'not-anonymous',
        message: 'An anonymous account is required to link Google.',
      );
    }
    try {
      await user.linkWithCredential(credential);
      return const GoogleLinkResult.linked();
    } on FirebaseAuthException catch (error) {
      if (error.code != 'credential-already-in-use') rethrow;
      return GoogleLinkResult.alreadyHasBackup(error.credential ?? credential);
    }
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) =>
      _auth.signInWithCredential(credential);

  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'You need to be signed in to delete your account.',
      );
    }
    final credential = await pickGoogleCredential();
    if (credential == null) {
      throw FirebaseAuthException(
        code: 'cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }
    await user.reauthenticateWithCredential(credential);
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

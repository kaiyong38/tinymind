import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  FakeFirebaseAuth({
    User? user,
    this.backupUser,
    this.anonymousSignInError,
  }) : _user = user {
    _watch(user);
    _watch(backupUser);
  }

  User? _user;
  final User? backupUser;
  Object? anonymousSignInError;
  final StreamController<User?> _changes = StreamController.broadcast();
  final StreamController<User?> _userChanges = StreamController.broadcast();
  int anonymousSignInCalls = 0;
  int signInCalls = 0;
  int credentialSignInCalls = 0;
  int signOutCalls = 0;

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> authStateChanges() => _changes.stream;

  @override
  Stream<User?> userChanges() => _userChanges.stream;

  /// Reports a sign-in change to both streams.
  void _emit() {
    _changes.add(_user);
    _userChanges.add(_user);
  }

  /// Reports changes to [user] itself, such as linking, on [userChanges].
  void _watch(User? user) {
    if (user is FakeFirebaseUser) {
      user.onChanged = () {
        if (identical(_user, user)) _userChanges.add(user);
      };
    }
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    anonymousSignInCalls++;
    final error = anonymousSignInError;
    if (error != null) throw error;
    _user = FakeFirebaseUser(uid: 'anonymous-uid', isAnonymous: true);
    _watch(_user);
    _emit();
    return FakeUserCredential(_user);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    final user = backupUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    _user = user;
    _emit();
    return FakeUserCredential(_user);
  }

  @override
  Future<UserCredential> signInWithCredential(
    AuthCredential credential,
  ) async {
    credentialSignInCalls++;
    final user = backupUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    _user = user;
    _emit();
    return FakeUserCredential(_user);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _emit();
  }

  Future<void> dispose() async {
    await _changes.close();
    await _userChanges.close();
  }
}

class FakeFirebaseUser extends Fake implements User {
  FakeFirebaseUser({
    required this.uid,
    required this.isAnonymous,
    this.email,
    bool emailProvider = false,
    bool googleProvider = false,
    this.linkError,
    this.emailVerified = true,
  }) : providerData = [
          if (emailProvider) FakeUserInfo(providerId: 'password'),
          if (googleProvider) FakeUserInfo(providerId: 'google.com'),
        ];

  @override
  final String uid;
  @override
  bool isAnonymous;
  @override
  final String? email;
  @override
  final List<UserInfo> providerData;
  final Object? linkError;
  @override
  bool emailVerified;
  int sendEmailVerificationCalls = 0;
  Object? sendEmailVerificationError;
  int reloadCalls = 0;
  AuthCredential? linkedCredential;
  int reauthenticationCalls = 0;
  int deleteCalls = 0;
  Object? deleteError;
  void Function()? onDelete;

  /// Called after the user changes, e.g. when a backup is linked.
  void Function()? onChanged;

  /// Thrown by [reauthenticateWithCredential] when set.
  Object? reauthenticationError;

  @override
  Future<void> delete() async {
    deleteCalls++;
    onDelete?.call();
    final error = deleteError;
    if (error != null) throw error;
  }

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    sendEmailVerificationCalls++;
    final error = sendEmailVerificationError;
    if (error != null) throw error;
  }

  @override
  Future<void> reload() async {
    reloadCalls++;
  }

  int getIdTokenCalls = 0;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    getIdTokenCalls++;
    return 'fake-id-token';
  }

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    final error = linkError;
    if (error != null) throw error;
    linkedCredential = credential;
    // Like Firebase, a linked account is no longer anonymous.
    isAnonymous = false;
    final providerId = credential.providerId;
    if (!providerData.any((info) => info.providerId == providerId)) {
      providerData.add(FakeUserInfo(providerId: providerId));
    }
    onChanged?.call();
    return FakeUserCredential(this);
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    reauthenticationCalls++;
    final error = reauthenticationError;
    if (error != null) throw error;
    return FakeUserCredential(this);
  }
}

class FakeUserInfo extends Fake implements UserInfo {
  FakeUserInfo({required this.providerId});

  @override
  final String providerId;
}

class FakeUserCredential extends Fake implements UserCredential {
  FakeUserCredential(this.user);

  @override
  final User? user;
}

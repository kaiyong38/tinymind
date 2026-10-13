import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  FakeFirebaseAuth({
    User? user,
    this.backupUser,
    this.anonymousSignInError,
  }) : _user = user;

  User? _user;
  final User? backupUser;
  Object? anonymousSignInError;
  final StreamController<User?> _changes = StreamController.broadcast();
  int anonymousSignInCalls = 0;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  User? get currentUser => _user;

  @override
  Stream<User?> authStateChanges() => _changes.stream;

  @override
  Future<UserCredential> signInAnonymously() async {
    anonymousSignInCalls++;
    final error = anonymousSignInError;
    if (error != null) throw error;
    _user = FakeFirebaseUser(uid: 'anonymous-uid', isAnonymous: true);
    _changes.add(_user);
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
    _changes.add(_user);
    return FakeUserCredential(_user);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
    _changes.add(null);
  }

  Future<void> dispose() => _changes.close();
}

class FakeFirebaseUser extends Fake implements User {
  FakeFirebaseUser({
    required this.uid,
    required this.isAnonymous,
    this.email,
    bool emailProvider = false,
    this.linkError,
  }) : providerData =
            emailProvider ? [FakeUserInfo(providerId: 'password')] : const [];

  @override
  final String uid;
  @override
  final bool isAnonymous;
  @override
  final String? email;
  @override
  final List<UserInfo> providerData;
  final Object? linkError;
  AuthCredential? linkedCredential;
  int reauthenticationCalls = 0;

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    final error = linkError;
    if (error != null) throw error;
    linkedCredential = credential;
    return FakeUserCredential(this);
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    reauthenticationCalls++;
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

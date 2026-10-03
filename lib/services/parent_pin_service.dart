import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A short PIN a parent sets up once and re-enters every time they tap
/// "Parent or teacher" — independent from their email/password, which is
/// only ever used to add or recover access to the account itself.
///
/// Stored hashed, on-device only (SharedPreferences), keyed by the
/// parent's uid. This is deliberately NOT stored in Firestore: it's a
/// per-device parental gate, not account data that needs to sync, and
/// keeping it local means it can never fail because of a security-rules
/// gap or a lost network connection — both of which would otherwise turn
/// "Parent or teacher" into a dead, unresponsive button.
class ParentPinService {
  String _key(String uid) => 'tinymind_parent_pin_$uid';

  Future<bool> hasPin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(uid)) != null;
  }

  Future<void> setPin(String uid, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(uid), _hash(pin));
  }

  Future<bool> verifyPin(String uid, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key(uid));
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();
}

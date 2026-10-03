import 'dart:convert';
import 'dart:math';

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
  static const _maxFailedAttempts = 5;
  static const _lockoutDuration = Duration(seconds: 30);

  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};

  String _key(String uid) => 'tinymind_parent_pin_$uid';

  Future<bool> hasPin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(uid)) != null;
  }

  Future<void> setPin(String uid, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(uid), _saltedHash(pin));
    _clearFailures(uid);
  }

  Future<bool> verifyPin(String uid, String pin) async {
    if (remainingLockoutSeconds(uid) > 0) return false;

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key(uid));
    if (stored == null) return false;

    final separator = stored.indexOf(':');
    final bool valid;
    if (separator < 0) {
      valid = stored == _legacyHash(pin);
      if (valid) {
        await prefs.setString(_key(uid), _saltedHash(pin));
      }
    } else {
      final salt = stored.substring(0, separator);
      final hash = stored.substring(separator + 1);
      valid = salt.isNotEmpty && hash == _hash(salt, pin);
    }

    if (valid) {
      _clearFailures(uid);
      return true;
    }
    final failures = (_failedAttempts[uid] ?? 0) + 1;
    if (failures >= _maxFailedAttempts) {
      _failedAttempts.remove(uid);
      _lockoutUntil[uid] = DateTime.now().add(_lockoutDuration);
    } else {
      _failedAttempts[uid] = failures;
    }
    return false;
  }

  int remainingLockoutSeconds(String uid) {
    final until = _lockoutUntil[uid];
    if (until == null) return 0;
    final remainingMilliseconds = until.difference(DateTime.now()).inMilliseconds;
    if (remainingMilliseconds <= 0) {
      _lockoutUntil.remove(uid);
      _failedAttempts.remove(uid);
      return 0;
    }
    return (remainingMilliseconds + 999) ~/ 1000;
  }

  void _clearFailures(String uid) {
    _failedAttempts.remove(uid);
    _lockoutUntil.remove(uid);
  }

  String _saltedHash(String pin) {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '$salt:${_hash(salt, pin)}';
  }

  String _legacyHash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt$pin')).toString();
}

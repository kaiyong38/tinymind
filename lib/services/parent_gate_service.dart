import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';

enum ParentLockMethod { phone, pin }

enum PinAttemptStatus { accepted, rejected, locked }

class PinAttemptResult {
  const PinAttemptResult(this.status, {this.remainingSeconds = 0});

  final PinAttemptStatus status;
  final int remainingSeconds;
}

abstract interface class ParentPhoneAuthenticator {
  Future<bool> isDeviceSupported();
  Future<bool> authenticate();
}

abstract interface class ParentGateStorage {
  Future<ParentLockMethod?> readMethod();
  Future<void> writeMethod(ParentLockMethod method);
  Future<String?> readPinRecord();
  Future<void> writePinRecord(String record);
}

abstract interface class ParentPasswordAuthenticator {
  Future<void> reauthenticate(String password);
}

class LocalAuthPhoneAuthenticator implements ParentPhoneAuthenticator {
  LocalAuthPhoneAuthenticator({LocalAuthentication? authentication})
      : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  @override
  Future<bool> isDeviceSupported() => _authentication.isDeviceSupported();

  @override
  Future<bool> authenticate() async {
    try {
      return await _authentication.authenticate(
        localizedReason: "Grown-ups only: confirm it's you",
      );
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}

class SharedPreferencesParentGateStorage implements ParentGateStorage {
  static const _methodKey = 'tinymind_parent_lock_method';
  static const _pinKey = 'tinymind_parent_lock_pin';

  @override
  Future<ParentLockMethod?> readMethod() async {
    final value = (await SharedPreferences.getInstance()).getString(_methodKey);
    return switch (value) {
      'phone' => ParentLockMethod.phone,
      'pin' => ParentLockMethod.pin,
      _ => null,
    };
  }

  @override
  Future<void> writeMethod(ParentLockMethod method) async {
    final saved = await (await SharedPreferences.getInstance())
        .setString(_methodKey, method.name);
    if (!saved) throw StateError('Could not save the grown-up lock method.');
  }

  @override
  Future<String?> readPinRecord() async =>
      (await SharedPreferences.getInstance()).getString(_pinKey);

  @override
  Future<void> writePinRecord(String record) async {
    final saved = await (await SharedPreferences.getInstance())
        .setString(_pinKey, record);
    if (!saved) throw StateError('Could not save the PIN on this device.');
  }
}

class ParentGateService {
  ParentGateService({
    ParentPhoneAuthenticator? phoneAuthenticator,
    ParentGateStorage? storage,
    ParentPasswordAuthenticator? passwordAuthenticator,
    AuthService? auth,
    DateTime Function()? clock,
  })  : _phoneAuthenticator =
            phoneAuthenticator ?? LocalAuthPhoneAuthenticator(),
        _storage = storage ?? SharedPreferencesParentGateStorage(),
        _passwordAuthenticator = passwordAuthenticator ??
            _AuthServicePasswordAuthenticator(auth),
        _auth = auth,
        _clock = clock ?? DateTime.now;

  static final ParentGateService instance = ParentGateService();
  static const _maxLockoutSeconds = 300;

  final ParentPhoneAuthenticator _phoneAuthenticator;
  final ParentGateStorage _storage;
  final ParentPasswordAuthenticator _passwordAuthenticator;
  final AuthService? _auth;
  final DateTime Function() _clock;

  int _failedPinAttempts = 0;
  int _lockoutLevel = 0;
  DateTime? _pinLockedUntil;

  Future<ParentLockMethod?> get selectedMethod async =>
      await _storage.readMethod() ?? ParentLockMethod.pin;

  bool get isPinLocked => _remainingLockoutSeconds > 0;

  int get _remainingLockoutSeconds {
    final until = _pinLockedUntil;
    if (until == null) return 0;
    final milliseconds = until.difference(_clock()).inMilliseconds;
    if (milliseconds <= 0) {
      _pinLockedUntil = null;
      return 0;
    }
    return (milliseconds + 999) ~/ 1000;
  }

  Future<bool> unlock(BuildContext context) async {
    final pinRecord = await _storage.readPinRecord();
    if (!context.mounted) return false;
    if (pinRecord == null) {
      final pin = await _showPinSetup(context);
      if (pin == null || !context.mounted) return false;
      await _savePin(pin);
      await _storage.writeMethod(ParentLockMethod.pin);
      return true;
    }

    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _PinEntryPage(
          initialLockoutSeconds: _remainingLockoutSeconds,
          onSubmit: verifyPin,
          onForgotPin: () => _recoverForgottenPin(context),
        ),
      ),
    );
    return accepted == true;
  }

  Future<bool> usePin(BuildContext context) async {
    final pin = await _showPinSetup(context);
    if (pin == null || !context.mounted) return false;
    await _savePin(pin);
    await _storage.writeMethod(ParentLockMethod.pin);
    return true;
  }

  Future<PinAttemptResult> verifyPin(String pin) async {
    final remaining = _remainingLockoutSeconds;
    if (remaining > 0) {
      return PinAttemptResult(
        PinAttemptStatus.locked,
        remainingSeconds: remaining,
      );
    }

    final storedRecord = await _storage.readPinRecord();
    if (storedRecord == null || !_matchesPin(storedRecord, pin)) {
      _failedPinAttempts++;
      if (_failedPinAttempts >= 5) {
        _startLockout();
        return PinAttemptResult(
          PinAttemptStatus.locked,
          remainingSeconds: _remainingLockoutSeconds,
        );
      }
      return const PinAttemptResult(PinAttemptStatus.rejected);
    }

    _failedPinAttempts = 0;
    return const PinAttemptResult(PinAttemptStatus.accepted);
  }

  Future<String?> _showPinSetup(BuildContext context) =>
      Navigator.of(context).push<String>(
        MaterialPageRoute<String>(builder: (_) => const _PinSetupPage()),
      );

  Future<void> _savePin(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final hash = sha256.convert([...salt, ...utf8.encode(pin)]).bytes;
    await _storage.writePinRecord('${_toHex(salt)}:${_toHex(hash)}');
    _failedPinAttempts = 0;
    _lockoutLevel = 0;
    _pinLockedUntil = null;
  }

  bool _matchesPin(String record, String pin) {
    final parts = record.split(':');
    if (parts.length != 2 || !RegExp(r'^\d{4}$').hasMatch(pin)) return false;
    final salt = _fromHex(parts[0]);
    final expected = _fromHex(parts[1]);
    if (salt == null || expected == null || expected.length != 32) return false;
    final actual = sha256.convert([...salt, ...utf8.encode(pin)]).bytes;
    var difference = 0;
    for (var i = 0; i < expected.length; i++) {
      difference |= expected[i] ^ actual[i];
    }
    return difference == 0;
  }

  String _toHex(List<int> bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  List<int>? _fromHex(String value) {
    if (value.isEmpty ||
        value.length.isOdd ||
        !RegExp(r'^[0-9a-f]+$').hasMatch(value)) {
      return null;
    }
    return [
      for (var i = 0; i < value.length; i += 2)
        int.parse(value.substring(i, i + 2), radix: 16),
    ];
  }

  Future<bool> _recoverForgottenPin(BuildContext context) async {
    final user = (_auth ?? AuthService()).currentUser;
    final emailLinked = user != null &&
        !user.isAnonymous &&
        user.email != null &&
        user.providerData.any((provider) => provider.providerId == 'password');
    if (emailLinked) {
      final password = await showDialog<String>(
        context: context,
        builder: (_) => const _ReauthenticateDialog(),
      );
      if (password == null || !context.mounted) return false;
      try {
        await _passwordAuthenticator.reauthenticate(password);
      } on FirebaseAuthException {
        return false;
      }
    } else {
      final phoneUnlockAvailable =
          await _phoneAuthenticator.isDeviceSupported();
      if (!context.mounted) return false;
      if (phoneUnlockAvailable) {
        if (!await _phoneAuthenticator.authenticate()) return false;
      } else {
        final wrongAttempts = await showDialog<int>(
          context: context,
          builder: (_) => const _AdultReadingCheckDialog(),
        );
        if (wrongAttempts == null || !context.mounted) return false;
        if (wrongAttempts >= 3) {
          _startLockout();
          return false;
        }
      }
    }
    if (!context.mounted) return false;
    final pin = await _showPinSetup(context);
    if (pin == null || !context.mounted) return false;
    await _savePin(pin);
    await _storage.writeMethod(ParentLockMethod.pin);
    return true;
  }

  void _startLockout() {
    final seconds = min(30 * (1 << min(_lockoutLevel, 4)), _maxLockoutSeconds);
    _lockoutLevel = min(_lockoutLevel + 1, 4);
    _failedPinAttempts = 0;
    _pinLockedUntil = _clock().add(Duration(seconds: seconds));
  }
}

class _AuthServicePasswordAuthenticator implements ParentPasswordAuthenticator {
  const _AuthServicePasswordAuthenticator(this.auth);

  final AuthService? auth;

  @override
  Future<void> reauthenticate(String password) =>
      (auth ?? AuthService()).reauthenticate(password);
}

class _AdultReadingCheckDialog extends StatefulWidget {
  const _AdultReadingCheckDialog();

  @override
  State<_AdultReadingCheckDialog> createState() =>
      _AdultReadingCheckDialogState();
}

class _AdultReadingCheckDialogState extends State<_AdultReadingCheckDialog> {
  int _wrongAnswers = 0;
  String? _message;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Grown-up check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The green frog hops over the small log.'),
            const SizedBox(height: 12),
            const Text('What hops over the log?'),
            if (_message != null) ...[
              const SizedBox(height: 8),
              Text(_message!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
        actions: [
          for (final answer in const ['Cat', 'Frog', 'Bird', 'Fish'])
            TextButton(
              onPressed: () {
                if (answer == 'Frog') {
                  Navigator.pop(context, _wrongAnswers);
                } else {
                  setState(() {
                    _wrongAnswers++;
                    _message = _wrongAnswers >= 3
                        ? 'Please wait before trying again.'
                        : 'That answer was not right. Try again.';
                  });
                  if (_wrongAnswers >= 3) Navigator.pop(context, 3);
                }
              },
              child: Text(answer),
            ),
        ],
      );
}

class _PinSetupPage extends StatefulWidget {
  const _PinSetupPage();

  @override
  State<_PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<_PinSetupPage> {
  String _digits = '';
  String? _firstPin;
  String? _message;

  void _press(int digit) {
    if (_digits.length >= 4) return;
    final next = '$_digits$digit';
    setState(() {
      _digits = next;
      _message = null;
    });
    if (next.length != 4) return;

    if (_firstPin == null) {
      setState(() {
        _firstPin = next;
        _digits = '';
      });
    } else if (_firstPin == next) {
      Navigator.pop(context, next);
    } else {
      setState(() {
        _firstPin = null;
        _digits = '';
        _message = 'Those PINs did not match. Please start again.';
      });
    }
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Set a 4-digit PIN')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final prompt = _PinPrompt(
                  instruction: _firstPin == null
                      ? 'Choose a PIN'
                      : 'Enter your PIN again',
                  digits: _digits.length,
                  message: _message,
                  note: _firstPin == null
                      ? 'This PIN is only for this device.\n'
                          'Grown-ups: please set this PIN yourself, not the child.'
                      : 'This PIN is only for this device.',
                );
                final pad = _PinNumberPad(
                  onDigit: _press,
                  onBackspace: _backspace,
                  enabled: true,
                );
                return _pinContentLayout(
                  constraints,
                  prompt: prompt,
                  pad: pad,
                );
              },
            ),
          ),
        ),
      );
}

class _PinEntryPage extends StatefulWidget {
  const _PinEntryPage({
    required this.initialLockoutSeconds,
    required this.onSubmit,
    required this.onForgotPin,
  });

  final int initialLockoutSeconds;
  final Future<PinAttemptResult> Function(String) onSubmit;
  final Future<bool> Function() onForgotPin;

  @override
  State<_PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<_PinEntryPage> {
  String _digits = '';
  String? _message;
  bool _busy = false;
  DateTime? _lockedUntil;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _setLockout(widget.initialLockoutSeconds);
  }

  void _setLockout(int seconds) {
    _timer?.cancel();
    if (seconds <= 0) {
      setState(() {
        _lockedUntil = null;
        _secondsRemaining = 0;
      });
      return;
    }
    _lockedUntil = DateTime.now().add(Duration(seconds: seconds));
    setState(() => _secondsRemaining = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _lockedUntil!.difference(DateTime.now()).inSeconds;
      setState(() {
        _secondsRemaining = remaining.clamp(0, 300);
        if (_secondsRemaining == 0) {
          _lockedUntil = null;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _press(int digit) async {
    if (_busy || _secondsRemaining > 0 || _digits.length >= 4) return;
    final next = '$_digits$digit';
    setState(() {
      _digits = next;
      _message = null;
    });
    if (next.length != 4) return;

    setState(() => _busy = true);
    try {
      final result = await widget.onSubmit(next);
      if (!mounted) return;
      if (result.status == PinAttemptStatus.accepted) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _busy = false;
        _digits = '';
        _message = result.status == PinAttemptStatus.locked
            ? null
            : 'That PIN was not right. Try again.';
      });
      if (result.status == PinAttemptStatus.locked) {
        _setLockout(result.remainingSeconds);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _digits = '';
        _message = 'Could not check the PIN: $error';
      });
    }
  }

  void _backspace() {
    if (_busy || _secondsRemaining > 0 || _digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _forgotPin() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final recovered = await widget.onForgotPin();
      if (!mounted) return;
      if (recovered) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _busy = false;
          _digits = '';
          _message = 'The PIN was not changed. Please try again.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _digits = '';
        _message = 'Could not update the PIN: $error';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Grown-ups only')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final prompt = Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PinPrompt(
                      instruction: 'Enter your 4-digit PIN',
                      digits: _digits.length,
                      message: _secondsRemaining > 0
                          ? 'Please wait $_secondsRemaining seconds.'
                          : _message,
                    ),
                    TextButton(
                      onPressed: _busy ? null : _forgotPin,
                      child: const Text('Forgot PIN?'),
                    ),
                  ],
                );
                final pad = _PinNumberPad(
                  onDigit: _press,
                  onBackspace: _backspace,
                  enabled: !_busy && _secondsRemaining == 0,
                );
                return _pinContentLayout(
                  constraints,
                  prompt: prompt,
                  pad: pad,
                );
              },
            ),
          ),
        ),
      );
}

Widget _pinContentLayout(
  BoxConstraints constraints, {
  required Widget prompt,
  required Widget pad,
}) {
  final keyboardWidth = min(360.0, constraints.maxWidth * 0.56);
  final keyboardHeight = min(
    constraints.maxHeight,
    4 * 64.0 + 3 * 4.0,
  );
  return Center(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, promptConstraints) => SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: promptConstraints.maxHeight,
                ),
                child: Center(child: prompt),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: keyboardWidth,
          height: keyboardHeight,
          child: SizedBox(
            height: keyboardHeight,
            child: pad,
          ),
        ),
      ],
    ),
  );
}

class _PinPrompt extends StatelessWidget {
  const _PinPrompt({
    required this.instruction,
    required this.digits,
    this.message,
    this.note,
  });

  final String instruction;
  final int digits;
  final String? message;
  final String? note;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_rounded, size: 42, color: Color(0xFFFF6FA5)),
          const SizedBox(height: 6),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(
              note!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < 4; index++)
                Container(
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < digits ? const Color(0xFFFF6FA5) : null,
                    border: Border.all(
                      color: const Color(0xFFFF6FA5),
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ],
      );
}

class _PinNumberPad extends StatelessWidget {
  const _PinNumberPad({
    required this.onDigit,
    required this.onBackspace,
    required this.enabled,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const labels = [
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '',
            '0',
            '⌫',
          ];
          const spacing = 4.0;
          final keyHeight = ((constraints.maxHeight - 3 * spacing) / 4)
              .clamp(48.0, 64.0)
              .toDouble();
          return GridView.count(
            padding: EdgeInsets.zero,
            primary: false,
            physics: const ClampingScrollPhysics(),
            crossAxisCount: 3,
            mainAxisExtent: keyHeight,
            mainAxisSpacing: spacing,
            crossAxisSpacing: 8,
            children: [
              for (final label in labels)
                if (label.isEmpty)
                  const SizedBox.shrink()
                else
                  _PinKey(
                    label: label,
                    enabled: enabled,
                    action: label == '⌫',
                    onTap: label == '⌫'
                        ? onBackspace
                        : () => onDigit(int.parse(label)),
                  ),
            ],
          );
        },
      );
}

class _PinKey extends StatelessWidget {
  const _PinKey({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.action = false,
  });

  final String label;
  final bool enabled;
  final bool action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: action || !enabled
            ? Colors.black.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      );
}

class _ReauthenticateDialog extends StatefulWidget {
  const _ReauthenticateDialog();

  @override
  State<_ReauthenticateDialog> createState() => _ReauthenticateDialogState();
}

class _ReauthenticateDialogState extends State<_ReauthenticateDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Confirm your account password'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('Continue'),
          ),
        ],
      );
}

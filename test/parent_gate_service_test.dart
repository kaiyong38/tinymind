import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/services/auth_service.dart';
import 'package:tinymind/services/parent_gate_service.dart';
import 'package:tinymind/widgets/large_screen_scaler.dart';

import 'support/fake_firebase_auth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first parent entry starts with a device-only PIN setup',
      (tester) async {
    final service = ParentGateService(storage: _FakeParentGateStorage());
    final harness = _UnlockHarness(service);
    await harness.mount(tester);
    await harness.tap(tester);
    expect(find.text('Choose a PIN'), findsOneWidget);
    expect(
      find.textContaining(
        'Grown-ups: please set this PIN yourself, not the child.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('This PIN is only for this device.'),
      findsOneWidget,
    );
  });

  testWidgets('each parent entry asks for the PIN, even after success',
      (tester) async {
    final service = ParentGateService(storage: _FakeParentGateStorage());
    final harness = _UnlockHarness(service);
    await harness.mount(tester);
    await harness.tap(tester);
    await _enterPin(tester, '2468');
    await _enterPin(tester, '2468');
    expect(harness.result, isTrue);

    await harness.tap(tester);
    expect(find.text('Enter your 4-digit PIN'), findsOneWidget);
    await _enterPin(tester, '2468');
    expect(harness.result, isTrue);
  });

  testWidgets('anonymous forgot PIN requires device authentication',
      (tester) async {
    final phone = _FakePhoneAuthenticator(supported: true);
    final service = ParentGateService(
      phoneAuthenticator: phone,
      storage: _FakeParentGateStorage(),
      auth: AuthService(
        auth: FakeFirebaseAuth(
          user: FakeFirebaseUser(uid: 'anon', isAnonymous: true),
        ),
      ),
    );
    final harness = _UnlockHarness(service);
    await harness.mount(tester);
    await harness.tap(tester);
    await _enterPin(tester, '2468');
    await _enterPin(tester, '2468');
    await harness.tap(tester);
    await tester.tap(find.text('Forgot PIN?'));
    await tester.pumpAndSettle();

    expect(phone.authenticateCalls, 1);
    expect(find.text('Choose a PIN'), findsOneWidget);
  });

  testWidgets('anonymous forgot PIN uses the reading check without screen lock',
      (tester) async {
    final service = ParentGateService(
      phoneAuthenticator: _FakePhoneAuthenticator(supported: false),
      storage: _FakeParentGateStorage(),
      auth: AuthService(
        auth: FakeFirebaseAuth(
          user: FakeFirebaseUser(uid: 'anon', isAnonymous: true),
        ),
      ),
    );
    final harness = _UnlockHarness(service);
    await harness.mount(tester);
    await harness.tap(tester);
    await _enterPin(tester, '2468');
    await _enterPin(tester, '2468');
    await harness.tap(tester);
    await tester.tap(find.text('Forgot PIN?'));
    await tester.pumpAndSettle();
    expect(find.text('The green frog hops over the small log.'), findsOneWidget);

    for (var attempt = 0; attempt < 3; attempt++) {
      await tester.tap(find.text('Cat'));
      await tester.pumpAndSettle();
    }
    expect(service.isPinLocked, isTrue);
    expect(find.text('Choose a PIN'), findsNothing);
  });

  testWidgets('linked-email forgot PIN re-authenticates first',
      (tester) async {
    final passwordAuthenticator = _FakePasswordAuthenticator();
    final service = ParentGateService(
      phoneAuthenticator: _FakePhoneAuthenticator(supported: false),
      storage: _FakeParentGateStorage(),
      passwordAuthenticator: passwordAuthenticator,
      auth: AuthService(
        auth: FakeFirebaseAuth(
          user: FakeFirebaseUser(
            uid: 'linked',
            isAnonymous: false,
            email: 'parent@example.com',
            emailProvider: true,
          ),
        ),
      ),
    );
    final harness = _UnlockHarness(service);
    await harness.mount(tester);
    await harness.tap(tester);
    await _enterPin(tester, '2468');
    await _enterPin(tester, '2468');
    await harness.tap(tester);
    await tester.tap(find.text('Forgot PIN?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'correct-password');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(passwordAuthenticator.calls, 1);
    expect(find.text('Choose a PIN'), findsOneWidget);
  });

  testWidgets('mismatched PIN confirmation is not stored', (tester) async {
    final storage = _FakeParentGateStorage();
    final service = ParentGateService(
      phoneAuthenticator: _FakePhoneAuthenticator(supported: false),
      storage: storage,
    );
    final harness = _UnlockHarness(service);

    await harness.mount(tester);
    await harness.tap(tester);
    await _enterPin(tester, '1234');
    await _enterPin(tester, '1235');

    expect(storage.pinRecord, isNull);
    expect(
      find.text('Those PINs did not match. Please start again.'),
      findsOneWidget,
    );
  });

  testWidgets('correct PIN succeeds and five wrong attempts lock out input',
      (tester) async {
    final storage = _FakeParentGateStorage();
    final service = ParentGateService(
      phoneAuthenticator: _FakePhoneAuthenticator(supported: false),
      storage: storage,
    );
    final harness = _UnlockHarness(service);

    await harness.mount(tester);
    await harness.tap(tester);
    await _enterPin(tester, '1234');
    await _enterPin(tester, '1234');
    expect(harness.result, isTrue);
    expect(
      storage.pinRecord,
      matches(RegExp(r'^[0-9a-f]{32}:[0-9a-f]{64}$')),
    );

    expect(
      (await service.verifyPin('1234')).status,
      PinAttemptStatus.accepted,
    );
    for (var attempt = 0; attempt < 4; attempt++) {
      expect(
        (await service.verifyPin('0000')).status,
        PinAttemptStatus.rejected,
      );
    }
    final fifthAttempt = await service.verifyPin('0000');
    expect(fifthAttempt.status, PinAttemptStatus.locked);
    expect(fifthAttempt.remainingSeconds, 30);
    expect(
      (await service.verifyPin('1234')).status,
      PinAttemptStatus.locked,
    );
  });

  testWidgets(
      'PIN lockout doubles after each five failures and caps at five minutes',
      (tester) async {
    var now = DateTime.utc(2026, 10, 4);
    final storage = _FakeParentGateStorage();
    final service = ParentGateService(
      phoneAuthenticator: _FakePhoneAuthenticator(supported: false),
      storage: storage,
      clock: () => now,
    );
    final harness = _UnlockHarness(service);

    await harness.mount(tester);
    await harness.tap(tester);
    await _enterPin(tester, '1234');
    await _enterPin(tester, '1234');

    for (final seconds in [30, 60, 120, 240, 300, 300]) {
      for (var attempt = 0; attempt < 4; attempt++) {
        expect(
          (await service.verifyPin('0000')).status,
          PinAttemptStatus.rejected,
        );
      }
      final result = await service.verifyPin('0000');
      expect(result.status, PinAttemptStatus.locked);
      expect(result.remainingSeconds, seconds);
      now = now.add(Duration(seconds: seconds + 1));
    }
  });

  testWidgets('PIN keypad keeps 3 columns and minimum key size at all sizes',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [
      const Size(568, 320),
      const Size(640, 360),
      const Size(732, 412),
      const Size(1280, 800),
      const Size(1024, 768),
      const Size(1920, 1080),
    ]) {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      final service = ParentGateService(
        phoneAuthenticator: _FakePhoneAuthenticator(supported: false),
        storage: _FakeParentGateStorage(),
      );
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(size),
          builder: (context, child) => LargeScreenScaler(child: child!),
          home: Builder(
            builder: (context) {
              if (!opened) {
                opened = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  service.usePin(context);
                });
              }
              return const Scaffold();
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Choose a PIN'), findsOneWidget, reason: '$size');
      expect(find.byType(GridView), findsOneWidget, reason: '$size');
      final first = tester.getCenter(_pinKeyFinder('1'));
      final second = tester.getCenter(_pinKeyFinder('2'));
      final third = tester.getCenter(_pinKeyFinder('3'));
      final fourth = tester.getCenter(_pinKeyFinder('4'));
      final eight = tester.getCenter(_pinKeyFinder('8'));
      final nine = tester.getCenter(_pinKeyFinder('9'));
      final zero = tester.getCenter(_pinKeyFinder('0'));
      final backspace = tester.getCenter(_pinKeyFinder('⌫'));
      final grid = tester.getRect(find.byType(GridView).first);
      final prompt = tester.getRect(
        find
            .ancestor(
              of: find.byIcon(Icons.shield_rounded),
              matching: find.byType(Column),
            )
            .first,
      );

      expect(first.dy, second.dy);
      expect(second.dy, third.dy);
      expect(fourth.dx, first.dx);
      expect(fourth.dy, greaterThan(first.dy));
      expect(zero.dx, eight.dx);
      expect(zero.dy, greaterThan(eight.dy));
      expect(backspace.dx, nine.dx);
      expect(backspace.dy, greaterThan(nine.dy));
      expect(
        (prompt.center.dy - grid.center.dy).abs(),
        lessThanOrEqualTo(1),
        reason: 'Prompt and keypad must stay centered at $size',
      );
      final scale = size.width >= 1920
          ? 2.7
          : size.width >= 1280
              ? 2.0
              : size.width >= 1024
                  ? 1.6
                  : size.width >= 732
                      ? 1.03
                      : 1.0;
      expect(grid.width / scale, lessThanOrEqualTo(360));
      expect(
        tester.getRect(_pinKeyFinder('1')).height / scale,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
    }
  });
}

Finder _pinKeyFinder(String label) => find
    .ancestor(of: find.text(label).last, matching: find.byType(InkWell))
    .first;

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.text(digit).last);
    await tester.pumpAndSettle();
  }
}

class _UnlockHarness {
  _UnlockHarness(this.service);

  final ParentGateService service;
  bool? result;

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await service.unlock(context);
                },
                child: const Text('Open grown-up area'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tap(WidgetTester tester) async {
    await tester.tap(find.text('Open grown-up area'));
    await tester.pumpAndSettle();
  }
}

class _FakePhoneAuthenticator implements ParentPhoneAuthenticator {
  _FakePhoneAuthenticator({required this.supported});

  final bool supported;
  final bool result = true;
  int authenticateCalls = 0;

  @override
  Future<bool> authenticate() async {
    authenticateCalls++;
    return result;
  }

  @override
  Future<bool> isDeviceSupported() async => supported;
}

class _FakeParentGateStorage implements ParentGateStorage {
  ParentLockMethod? method;
  String? pinRecord;

  @override
  Future<ParentLockMethod?> readMethod() async => method;

  @override
  Future<String?> readPinRecord() async => pinRecord;

  @override
  Future<void> writeMethod(ParentLockMethod method) async {
    this.method = method;
  }

  @override
  Future<void> writePinRecord(String record) async {
    pinRecord = record;
  }
}

class _FakePasswordAuthenticator implements ParentPasswordAuthenticator {
  int calls = 0;

  @override
  Future<void> reauthenticate(String password) async {
    calls++;
  }
}

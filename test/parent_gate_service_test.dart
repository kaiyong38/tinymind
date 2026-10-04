import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/services/parent_gate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone unlock success is remembered for five minutes',
      (tester) async {
    final phone = _FakePhoneAuthenticator(supported: true, result: true);
    final storage = _FakeParentGateStorage(method: ParentLockMethod.phone);
    final service = ParentGateService(
      phoneAuthenticator: phone,
      storage: storage,
    );
    final harness = _UnlockHarness(service);

    await harness.mount(tester);
    await harness.tap(tester);
    expect(harness.result, isTrue);
    await harness.tap(tester);

    expect(phone.authenticateCalls, 1);
    expect(harness.result, isTrue);
  });

  testWidgets('phone unlock expires after five minutes', (tester) async {
    var now = DateTime.utc(2026, 10, 4);
    final phone = _FakePhoneAuthenticator(supported: true, result: true);
    final service = ParentGateService(
      phoneAuthenticator: phone,
      storage: _FakeParentGateStorage(method: ParentLockMethod.phone),
      clock: () => now,
    );
    final harness = _UnlockHarness(service);

    await harness.mount(tester);
    await harness.tap(tester);
    now = now.add(const Duration(minutes: 5, seconds: 1));
    await harness.tap(tester);

    expect(phone.authenticateCalls, 2);
    expect(harness.result, isTrue);
  });

  testWidgets('cancelled phone authentication returns false', (tester) async {
    final phone = _FakePhoneAuthenticator(supported: true, result: false);
    final service = ParentGateService(
      phoneAuthenticator: phone,
      storage: _FakeParentGateStorage(method: ParentLockMethod.phone),
    );
    final harness = _UnlockHarness(service);

    await harness.mount(tester);
    await harness.tap(tester);

    expect(harness.result, isFalse);
  });

  testWidgets('unsupported phone lock falls back to PIN setup', (tester) async {
    final storage = _FakeParentGateStorage(method: ParentLockMethod.phone);
    final service = ParentGateService(
      phoneAuthenticator: _FakePhoneAuthenticator(supported: false),
      storage: storage,
    );
    final harness = _UnlockHarness(service);

    await harness.mount(tester);
    await harness.tap(tester);

    expect(storage.method, ParentLockMethod.pin);
    expect(find.text('Choose a PIN'), findsOneWidget);
  });

  testWidgets('no saved lock method opens the one-time method choice',
      (tester) async {
    final service = ParentGateService(
      phoneAuthenticator: _FakePhoneAuthenticator(supported: true),
      storage: _FakeParentGateStorage(),
    );
    final harness = _UnlockHarness(service);

    await harness.mount(tester);
    await harness.tap(tester);

    expect(find.text('Set up grown-up lock'), findsOneWidget);
    expect(find.textContaining('Use my phone'), findsOneWidget);
    expect(find.text('Use a 4-digit PIN'), findsOneWidget);
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
    await tester.tap(find.text('Use a 4-digit PIN'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text('Use a 4-digit PIN'));
    await tester.pumpAndSettle();
    await _enterPin(tester, '1234');
    await _enterPin(tester, '1234');
    expect(harness.result, isTrue);
    expect(
      storage.pinRecord,
      matches(RegExp(r'^[0-9a-f]{32}:[0-9a-f]{64}$')),
    );

    service.clearVerificationWindow();
    expect(
      (await service.verifyPin('1234')).status,
      PinAttemptStatus.accepted,
    );
    service.clearVerificationWindow();
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

  testWidgets('clearing verification requires phone authentication again',
      (tester) async {
    final phone = _FakePhoneAuthenticator(supported: true, result: true);
    final service = ParentGateService(
      phoneAuthenticator: phone,
      storage: _FakeParentGateStorage(method: ParentLockMethod.phone),
    );
    final harness = _UnlockHarness(service);

    await harness.mount(tester);
    await harness.tap(tester);
    service.clearVerificationWindow();
    await harness.tap(tester);

    expect(phone.authenticateCalls, 2);
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
    await tester.tap(find.text('Use a 4-digit PIN'));
    await tester.pumpAndSettle();
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
}

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
            body: TextButton(
              onPressed: () async {
                result = await service.unlock(context);
              },
              child: const Text('Open grown-up area'),
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
  _FakePhoneAuthenticator({
    required this.supported,
    this.result = true,
  });

  final bool supported;
  final bool result;
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
  _FakeParentGateStorage({this.method});

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

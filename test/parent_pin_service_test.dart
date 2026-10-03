import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/services/parent_pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores a salted hash and verifies the PIN', () async {
    final service = ParentPinService();
    await service.setPin('parent', '1234');

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('tinymind_parent_pin_parent')!;
    final parts = stored.split(':');
    expect(parts, hasLength(2));
    expect(parts[0], hasLength(32));
    expect(parts[1], sha256.convert(utf8.encode('${parts[0]}1234')).toString());
    expect(await service.verifyPin('parent', '1234'), isTrue);
    expect(await service.verifyPin('parent', '4321'), isFalse);
  });

  test('migrates a legacy hash after successful verification', () async {
    final prefs = await SharedPreferences.getInstance();
    final legacyHash = sha256.convert(utf8.encode('2468')).toString();
    await prefs.setString('tinymind_parent_pin_parent', legacyHash);

    final service = ParentPinService();
    expect(await service.verifyPin('parent', '2468'), isTrue);

    final migrated = prefs.getString('tinymind_parent_pin_parent')!;
    expect(migrated.split(':'), hasLength(2));
    expect(migrated.split(':').first, hasLength(32));
  });

  test('locks after five failures and reports remaining seconds', () async {
    final service = ParentPinService();
    await service.setPin('parent', '1234');

    for (var attempt = 0; attempt < 5; attempt++) {
      expect(await service.verifyPin('parent', '0000'), isFalse);
    }
    expect(service.remainingLockoutSeconds('parent'), inInclusiveRange(1, 30));
    expect(await service.verifyPin('parent', '1234'), isFalse);
    expect(service.remainingLockoutSeconds('other'), 0);
  });
}

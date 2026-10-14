import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/services/narration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ttsChannel = MethodChannel('flutter_tts');
  const focusChannel = MethodChannel('tinymind/speech_audio_focus');
  final calls = <MethodCall>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ttsChannel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'getEngines':
          return <String>['test-engine'];
        case 'isLanguageAvailable':
          return true;
        default:
          return 1;
      }
    });
    messenger.setMockMethodCallHandler(focusChannel, (call) async => true);
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ttsChannel, null);
    messenger.setMockMethodCallHandler(focusChannel, null);
  });

  test('voice volume defaults to 1.0', () async {
    final narration = NarrationService();
    await narration.init();

    expect(narration.voiceVolume, 1.0);
  });

  test('voice volume is fixed at 1.0 and ignores old stored values', () async {
    SharedPreferences.setMockInitialValues({'tinymind_voice_volume': 0.5});
    final narration = NarrationService();
    await narration.init();
    expect(narration.voiceVolume, 1.0);

    final volumeCalls = calls.where((call) => call.method == 'setVolume');
    expect(volumeCalls, isNotEmpty);
    expect(volumeCalls.every((call) => call.arguments == 1.0), isTrue);
  });
}

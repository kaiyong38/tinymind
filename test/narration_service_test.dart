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

  test('voice volume is clamped and persisted across initialization', () async {
    final narration = NarrationService();
    await narration.init();
    await narration.setVoiceVolume(0.1);
    expect(narration.voiceVolume, 0.3);

    await narration.setVoiceVolume(0.5);
    await narration.saveVoiceVolume();

    final restored = NarrationService();
    await restored.init();
    expect(restored.voiceVolume, 0.5);
  });

  test('setVoiceVolume updates the TTS volume', () async {
    final narration = NarrationService();
    await narration.init();
    calls.clear();

    await narration.setVoiceVolume(0.5);

    final volumeCalls = calls.where((call) => call.method == 'setVolume');
    expect(volumeCalls, hasLength(1));
    expect(volumeCalls.single.arguments, 0.5);
  });
}

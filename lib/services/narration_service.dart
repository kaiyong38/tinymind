import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_text_helper.dart';

/// Reads short bits of text aloud (question prompts, "let's learn it"
/// facts, right/wrong feedback) so a 3-6 year old who can't read yet isn't
/// blocked by on-screen text. Uses the device's own text-to-speech voice —
/// no audio assets needed.
///
/// The voice is set up to sound bright and playful (higher pitch, a brisk
/// pace), and every utterance is cleaned by [TtsTextHelper] before playback.
class NarrationService {
  NarrationService._();
  static final NarrationService instance = NarrationService._();

  final FlutterTts _tts = FlutterTts();
  static const MethodChannel _audioFocusChannel =
      MethodChannel('tinymind/speech_audio_focus');
  bool _ready = false;
  int _speakId = 0;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.5);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // If the platform has no TTS engine available, narration silently
      // becomes a no-op rather than crashing the app.
    }
  }

  Future<void> speak(String text, {String? spokenText}) async {
    if (!_ready) await init();
    final speakId = ++_speakId;
    try {
      try {
        await _tts.stop();
        if (speakId != _speakId) return;
        _tts.setCompletionHandler(() => _releaseAudioFocus(speakId));
        _tts.setCancelHandler(() => _releaseAudioFocus(speakId));
        _tts.setErrorHandler((_) => _releaseAudioFocus(speakId));
        await _audioFocusChannel.invokeMethod<bool>('requestTransientFocus');
        if (speakId != _speakId) return;
        await _tts.speak(TtsTextHelper.clean(spokenText ?? text));
      } finally {
        await _releaseAudioFocus(speakId);
      }
    } catch (_) {
      // No-op if TTS isn't available on this device.
    }
  }

  Future<void> stop() async {
    ++_speakId;
    await _tts.stop();
    await _releaseAudioFocus();
  }

  Future<void> _releaseAudioFocus([int? speakId]) async {
    if (speakId != null && speakId != _speakId) return;
    await _audioFocusChannel.invokeMethod<void>('releaseFocus');
  }
}

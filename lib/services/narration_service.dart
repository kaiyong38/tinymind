import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'tts_text_helper.dart';

abstract interface class NarrationService {
  static final NarrationService instance = _DeviceNarrationService();
  factory NarrationService() => _DeviceNarrationService();

  bool get voiceAvailable;
  double get voiceVolume;

  Future<void> init();
  Future<void> speak(String text, {String? spokenText});
  Future<void> stop();
}

/// Reads short bits of text aloud using the device's text-to-speech voice.
/// Every utterance is cleaned by [TtsTextHelper] before playback.
class _DeviceNarrationService implements NarrationService {
  static const _fixedVoiceVolume = 1.0;

  @override
  bool get voiceAvailable => _voiceAvailable;

  @override
  double get voiceVolume => _fixedVoiceVolume;

  final FlutterTts _tts = FlutterTts();
  static const MethodChannel _audioFocusChannel =
      MethodChannel('tinymind/speech_audio_focus');
  bool _ready = false;
  bool _voiceAvailable = false;
  int _speakId = 0;

  @override
  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      final engines = await _tts.getEngines;
      final hasEngine = engines is List && engines.isNotEmpty;
      final hasEnglishVoice =
          hasEngine && await _tts.isLanguageAvailable('en-US') == true;
      _voiceAvailable = hasEngine && hasEnglishVoice;
    } catch (_) {
      _voiceAvailable = false;
      // If the platform cannot report its TTS engine, treat voice as absent.
    }
    if (!_voiceAvailable) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.5);
      await _tts.setVolume(_fixedVoiceVolume);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {
      // Keep app startup working if an optional voice setting is unsupported.
    }
  }

  @override
  Future<void> speak(String text, {String? spokenText}) async {
    if (!_ready) await init();
    final speakId = ++_speakId;
    try {
      try {
        await _tts.stop();
        if (speakId != _speakId) return;
        await _tts.setVolume(_fixedVoiceVolume);
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

  @override
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

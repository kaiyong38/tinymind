import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tts_text_helper.dart';

abstract interface class NarrationService {
  static final NarrationService instance = _DeviceNarrationService();
  factory NarrationService() => _DeviceNarrationService();

  bool get voiceAvailable;
  double get voiceVolume;
  ValueNotifier<double> get voiceVolumeNotifier;

  Future<void> init();
  Future<void> speak(String text, {String? spokenText});
  Future<void> setVoiceVolume(double volume);
  Future<void> saveVoiceVolume();
  Future<void> stop();
}

/// Reads short bits of text aloud using the device's text-to-speech voice.
/// Every utterance is cleaned by [TtsTextHelper] before playback.
class _DeviceNarrationService implements NarrationService {
  static const _voiceVolumeKey = 'tinymind_voice_volume';
  static const _minimumVoiceVolume = 0.3;

  @override
  bool get voiceAvailable => _voiceAvailable;

  @override
  double get voiceVolume => _voiceVolume.value;

  @override
  ValueNotifier<double> get voiceVolumeNotifier => _voiceVolume;

  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<double> _voiceVolume = ValueNotifier<double>(1.0);
  static const MethodChannel _audioFocusChannel =
      MethodChannel('tinymind/speech_audio_focus');
  bool _ready = false;
  bool _voiceAvailable = false;
  int _speakId = 0;

  @override
  Future<void> init() async {
    if (_ready) return;
    final preferences = await SharedPreferences.getInstance();
    _voiceVolume.value = (preferences.getDouble(_voiceVolumeKey) ?? 1.0)
        .clamp(_minimumVoiceVolume, 1.0)
        .toDouble();
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
      await _tts.setVolume(_voiceVolume.value);
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
        await _tts.setVolume(_voiceVolume.value);
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
  Future<void> setVoiceVolume(double volume) async {
    _voiceVolume.value =
        volume.clamp(_minimumVoiceVolume, 1.0).toDouble();
    await _tts.setVolume(_voiceVolume.value);
  }

  @override
  Future<void> saveVoiceVolume() async {
    final saved = await (await SharedPreferences.getInstance())
        .setDouble(_voiceVolumeKey, _voiceVolume.value);
    if (!saved) throw StateError('Could not save the voice volume.');
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

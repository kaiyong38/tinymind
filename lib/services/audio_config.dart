import 'package:audioplayers/audioplayers.dart';

/// Shared platform audio settings for TinyMind playback.
class AudioConfig {
  AudioConfig._();

  static AudioContext get backgroundMusic => AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      );
}

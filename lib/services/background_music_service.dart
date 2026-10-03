import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which looping music bed is playing.
enum MusicTrack {
  /// Gentle, calm loop for the home / "Grown-ups" screens, and the very
  /// first "who is learning today?" screen the app opens on.
  playtime('audio/bg_music.mp3'),

  /// One distinct loop per learning world, so Letter Land sounds
  /// different from Math Town, Shape Safari, and Color Garden instead of
  /// sharing a single generic "quiz" bed.
  quizLetters('audio/quiz_letters.mp3'),
  quizNumbers('audio/quiz_numbers.mp3'),
  quizShapes('audio/quiz_shapes.mp3'),
  quizColors('audio/quiz_colors.mp3');

  const MusicTrack(this.asset);
  final String asset;

  /// Maps a [LearningModule.id] to its music track, falling back to
  /// [quizLetters] for any module id this doesn't recognise (safer than
  /// crashing if a new module is added without updating this list).
  static MusicTrack forModule(String moduleId) {
    switch (moduleId) {
      case 'letters':
        return MusicTrack.quizLetters;
      case 'numbers':
        return MusicTrack.quizNumbers;
      case 'shapes':
        return MusicTrack.quizShapes;
      case 'colors':
        return MusicTrack.quizColors;
      default:
        return MusicTrack.quizLetters;
    }
  }
}

/// Plays a looping, low-volume background music track while a child is in
/// the app, and remembers whether the grown-up muted it last time.
///
/// Five tracks ship in `assets/audio/` (already declared in pubspec.yaml
/// via the whole-folder entry): a calm one for browsing/menus, plus one
/// per learning world (Letter Land, Math Town, Shape Safari, Color Garden) —
/// see [MusicTrack.forModule]. If a module-specific file is ever missing,
/// [play] quietly falls back to the calm menu track rather than staying
/// silent or crashing.
///
/// If you build this and still hear nothing: check the device/emulator's
/// *media* volume specifically (separate from ringtone/notification volume —
/// on the Android emulator use the volume keys or Extended Controls, since
/// media can default to a low level even when the UI looks fully alive),
/// and check the `flutter run` console for a line starting with
/// "BackgroundMusicService:", which this class prints if playback fails.
class BackgroundMusicService {
  BackgroundMusicService._();
  static final BackgroundMusicService instance = BackgroundMusicService._();

  static const _mutedKey = 'tinymind_music_muted';

  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;
  MusicTrack? _current;

  /// True while music was auto-paused because the app went to the
  /// background — distinct from [_muted], which is the grown-up's
  /// deliberate choice. Keeping them separate means backgrounding the app
  /// never flips the mute switch the parent sees.
  bool _pausedForBackground = false;

  bool get isMuted => _muted;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_mutedKey) ?? false;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(0.5);
    // Force playback onto the media/music stream and ignore the device's
    // silent switch — otherwise some Android devices/emulators route audio
    // through a stream that is muted by default even though the app looks
    // like it's working fine.
    await _player.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransient,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }

  /// Starts (or switches to) [track]. Safe to call repeatedly — it only
  /// restarts playback if the track actually changed.
  Future<void> play(MusicTrack track) async {
    if (_muted) {
      _current = track;
      return;
    }
    if (_current == track) return;
    _current = track;
    try {
      await _player.play(AssetSource(track.asset));
    } catch (error) {
      // Surface the real reason in the run console instead of failing
      // silently, so a missing/misnamed asset is easy to spot.
      debugPrint('BackgroundMusicService: failed to play ${track.asset}: $error');
      // Fall back to the one track every install is guaranteed to have,
      // so a missing per-world file means "quieter than intended" rather
      // than "no music at all for this screen".
      if (track != MusicTrack.playtime) {
        _current = null;
        await play(MusicTrack.playtime);
      }
    }
  }

  Future<void> toggleMute() async {
    _muted = !_muted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, _muted);
    if (_muted) {
      await _player.pause();
    } else if (_current != null) {
      final track = _current!;
      _current = null;
      await play(track);
    }
  }

  /// Called when the app is backgrounded (another app comes to the
  /// foreground, the phone is locked, etc.) — without this, `audioplayers`
  /// keeps looping music even while TinyMind isn't the visible app, which
  /// is the "music won't stop until I force-close it" bug.
  Future<void> pauseForBackground() async {
    if (_muted) return; // Already silent; nothing to pause.
    _pausedForBackground = true;
    await _player.pause();
  }

  /// Called when the app returns to the foreground — resumes only if it
  /// was *this* auto-pause that stopped it, never overriding a grown-up's
  /// explicit mute.
  Future<void> resumeFromBackground() async {
    if (!_pausedForBackground) return;
    _pausedForBackground = false;
    if (!_muted) await _player.resume();
  }

  Future<void> dispose() => _player.dispose();
}

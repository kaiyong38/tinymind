import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/services/music_settings.dart';

void main() {
  test('missing saved settings default to audible at volume 0.5', () {
    final settings = MusicSettings.fromSaved();

    expect(settings.isMuted, isFalse);
    expect(settings.volume, 0.5);
    expect(settings.previousVolume, 0.5);
  });

  test('saved mute remains muted on startup', () {
    final settings = MusicSettings.fromSaved(
      isMuted: true,
      volume: 0,
      previousVolume: 0.7,
    );

    expect(settings.isMuted, isTrue);
    expect(settings.volume, 0);
    expect(settings.previousVolume, 0.7);
  });

  test('moving volume to zero mutes, then moving above zero unmutes', () {
    final muted = const MusicSettings().setVolume(0);
    final audible = muted.setVolume(0.35);

    expect(muted.isMuted, isTrue);
    expect(muted.volume, 0);
    expect(muted.previousVolume, 0.5);
    expect(audible.isMuted, isFalse);
    expect(audible.volume, 0.35);
  });

  test('mute toggle restores the volume that was active before muting', () {
    final muted = const MusicSettings().setVolume(0.72).toggleMute();
    final restored = muted.toggleMute();

    expect(muted.isMuted, isTrue);
    expect(muted.previousVolume, 0.72);
    expect(restored.isMuted, isFalse);
    expect(restored.volume, 0.72);
  });

  test('mute toggle restores default volume when previous volume is very low',
      () {
    final muted = const MusicSettings().setVolume(0.05).toggleMute();
    final restored = muted.toggleMute();

    expect(restored.isMuted, isFalse);
    expect(restored.volume, 0.5);
  });

  test('volume is clamped to the supported range', () {
    expect(const MusicSettings().setVolume(-1).volume, 0);
    expect(const MusicSettings().setVolume(2).volume, 1);
  });
}

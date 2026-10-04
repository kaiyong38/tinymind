class MusicSettings {
  const MusicSettings({
    this.isMuted = false,
    this.volume = 0.5,
    this.previousVolume = 0.5,
  });

  final bool isMuted;
  final double volume;
  final double previousVolume;

  MusicSettings setVolume(double value) {
    final nextVolume = value.clamp(0.0, 1.0).toDouble();
    if (nextVolume == 0) {
      return MusicSettings(
        isMuted: true,
        volume: 0,
        previousVolume:
            isMuted ? previousVolume : (volume > 0 ? volume : previousVolume),
      );
    }
    return MusicSettings(
      isMuted: false,
      volume: nextVolume,
      previousVolume: nextVolume,
    );
  }

  MusicSettings toggleMute() {
    if (isMuted || volume == 0) {
      final restoredVolume = previousVolume < 0.1 ? 0.5 : previousVolume;
      return MusicSettings(
        isMuted: false,
        volume: restoredVolume,
        previousVolume: restoredVolume,
      );
    }
    return MusicSettings(
      isMuted: true,
      volume: 0,
      previousVolume: volume,
    );
  }

  factory MusicSettings.fromSaved({
    bool? isMuted,
    double? volume,
    double? previousVolume,
  }) {
    final savedPreviousVolume =
        (previousVolume ?? volume ?? 0.5).clamp(0.0, 1.0).toDouble();
    final muted = isMuted ?? false;
    final savedVolume = muted
        ? 0.0
        : (volume ?? 0.5).clamp(0.0, 1.0).toDouble();
    return MusicSettings(
      isMuted: muted || savedVolume == 0,
      volume: savedVolume,
      previousVolume:
          savedPreviousVolume < 0.1 ? 0.5 : savedPreviousVolume,
    );
  }
}

abstract class BaseVideoController {
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Future<void> setPlaybackRate(double playbackrate);
  Duration get position;
  Duration get duration;
  bool get isPlaying;
  Future<void> dispose();
}

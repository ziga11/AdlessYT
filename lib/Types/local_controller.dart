import 'package:adless_youtube/Types/base_video_controller.dart';
import 'package:video_player/video_player.dart';

class LocalControllerWrapper implements BaseVideoController {
  final VideoPlayerController controller;

  LocalControllerWrapper(this.controller);

  @override
  Future<void> play() async => controller.play();

  @override
  Future<void> pause() async => controller.pause();

  @override
  Future<void> seekTo(Duration position) async => controller.seekTo(position);

  @override
  Duration get position => controller.value.position;

  @override
  Duration get duration => controller.value.duration;

  @override
  bool get isPlaying => controller.value.isPlaying;

  @override
  Future<void> dispose() async => controller.dispose();

  @override
  Future<void> setPlaybackRate(double playbackrate) async {
    controller.setPlaybackSpeed(playbackrate);
  }
}

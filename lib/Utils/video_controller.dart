import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum Looping { no, playlist, one }

class VideoController {
  static Looping looping = Looping.playlist;
  static YoutubePlayerController? youtubeController = YoutubePlayerController(
    initialVideoId: "dQw4w9WgXcQ",
    flags: const YoutubePlayerFlags(
      autoPlay: false,
      hideControls: true,
    ),
  );
  static List<dynamic>? videos;
  static int index = 0;

  void setVideos({required List<dynamic> vids, int ind = 0}) {
    videos = vids;
    index = ind;
    if (vids[0] is Video) {
      youtubeController = YoutubePlayerController(
          initialVideoId: (vids[index] as Video).id.value,
          flags: const YoutubePlayerFlags(hideControls: true));
    } else {}
  }
}

  /* YoutubePlayerController initYTController() {
    YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: "dQw4w9WgXcQ",
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        hideControls: true,
      ),
    );
    controller.pause();

    return controller;
  } */

import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum Looping { no, playlist, one }

class VideoController {
  bool videoPage = true;
  YoutubePlayerController? youtubeController;

  void setVideos({required List<dynamic> videos, int index = 0}) async {
    if (videos[0] is Video) {
      youtubeController =
          YoutubePlayerController(initialVideoId: videos[index]);
    } else {}
  }
}

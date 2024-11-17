import 'dart:io';
import 'dart:math';

import 'package:adless_youtube/Pages/video_player.dart';
import 'package:adless_youtube/Types/base_video_controller.dart';
import 'package:adless_youtube/Types/local_controller.dart';
import 'package:adless_youtube/Types/video_source.dart';
import 'package:adless_youtube/Types/youtube_controller.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum Looping {
  none,
  playlist,
  one,
}

class VideoPlayerProvider extends ChangeNotifier {
  String? lastRoute;
  Map<String, dynamic>? lastRouteArgs;
  Function()? getLastRouteArgs;

  /* Is extended by LocalVideoWrapper and YoutubeVideoWrapper*/
  final ValueNotifier<BaseVideoController?> _controller = ValueNotifier(null);

  /* Whether is YT or Local */
  final ValueNotifier<VideoSource?> _currentSource = ValueNotifier(null);
  final ValueNotifier<bool> _playing = ValueNotifier(true);
  final ValueNotifier<double> _controlOpacity = ValueNotifier(0.0);

  /* Whether or not the Pause, Slider, ... controls are visible or not */
  final ValueNotifier<bool> _showControls = ValueNotifier(false);
  final ValueNotifier<bool?> mainPage = ValueNotifier(null);

  final ValueNotifier<int> index = ValueNotifier(0);

  Looping looping = Looping.playlist;
  List<String> _currentLocalPaths = [];
  List<Video> videos = [];

  Widget? _activePlayer;
  final VideoPage _videoPage = const VideoPage();

  ValueNotifier<BaseVideoController?> get controller => _controller;
  ValueNotifier<VideoSource?> get currentSource => _currentSource;
  ValueNotifier<bool> get playing => _playing;
  ValueNotifier<double> get controlOpacityNotifier => _controlOpacity;
  ValueNotifier<bool> get showControlsNotifier => _showControls;
  Video? get currentVideo => videos[index.value];
  String? get currentLocalPath => _currentLocalPaths[index.value];
  Widget? get activePlayer => _activePlayer;
  VideoPage get videoPage => _videoPage;

  Future<void> initializeYoutubeVideo(List<Video> vids) async {
    if (videos == vids && _currentSource.value == VideoSource.youtube) return;

    index.value = 0;
    /*  NO NEED TO REINITALIZE THE CONTROLLER
        iF ITS YT CONTROLLER, JUST LOAD THE NEW VIDEO */
    if (mainPage.value != null) {
      videos = vids;
      (_controller.value as YoutubeControllerWrapper)
          .controller
          .load(vids[index.value].id.value);
    } else {
      await _dispose();

      final controller = YoutubePlayerController(
        initialVideoId: vids[index.value].id.value,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          hideControls: true,
        ),
      );

      controller.addListener(() {
        if (controller.value.position != vids[index.value].duration) return;
        switch (looping) {
          case Looping.one:
            controller.seekTo(const Duration(seconds: 0));
            break;
          case Looping.playlist:
            index.value = (index.value + 1) % vids.length;
            controller.load(vids[index.value].id.value);
            break;
          case Looping.none:
            index.value++;
            if (index.value == vids.length) return;
            controller.load(vids[index.value].id.value);
            break;
        }
      });

      _controller.value = YoutubeControllerWrapper(controller);
      videos = vids;
      _currentSource.value = VideoSource.youtube;
      await initializePlayer();
      mainPage.value = true;
    }
  }

  Future<void> switchToVideo(int ind) async {
    if (index.value == ind || videos.length <= ind) return;
    (_controller.value as YoutubeControllerWrapper)
        .controller
        .load(videos[ind].id.value);
  }

  Future<void> initializeLocalVideo(
      List<Video> vids, List<String> filePaths) async {
    if (_currentLocalPaths == filePaths &&
        _currentSource.value == VideoSource.local) {
      return;
    }

    await _dispose();

    _currentLocalPaths = filePaths;
    _currentSource.value = VideoSource.local;

    videos = vids;

    final controller = VideoPlayerController.file(
      File(filePaths[index.value]),
    );

    await controller.initialize();
    _controller.value = LocalControllerWrapper(controller);
    await initializePlayer();
    mainPage.value = true;
  }

  Future<void> initializePlayer() async {
    if (currentSource.value == VideoSource.youtube) {
      _activePlayer = YoutubePlayer(
        controller: (controller.value as YoutubeControllerWrapper).controller,
        key: const ValueKey('youtube_player'),
      );
    } else {
      _activePlayer = VideoPlayer(
        (controller.value as LocalControllerWrapper).controller,
        key: const ValueKey('local_player'),
      );
    }
  }

  Future<void> togglePlayPause() async {
    if (_controller.value == null) return;

    if (_playing.value) {
      await _controller.value!.pause();
    } else {
      await _controller.value!.play();
    }
    _playing.value = !_playing.value;
  }

  Future<void> seekTo(Duration position) async {
    await _controller.value?.seekTo(position);
  }

  void updateControlsVisibility(bool show, double opacity) {
    _showControls.value = show;
    _controlOpacity.value = max(opacity, 0);
  }

  Future<void> _dispose() async {
    if (_controller.value != null) {
      await _controller.value?.dispose();
      _controller.value = null;
    }
    _currentLocalPaths = [];
    videos.clear();
    _activePlayer = null;
    _playing.value = false;
    mainPage.value = null;
  }

  Future<void> setMainPage(bool? mPage) async {
    await Future.microtask(() {
      mainPage.value = mPage;
    });
  }

  Future<void> disposeWithoutProvider() async {
    await _dispose();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await _dispose();
  }
}

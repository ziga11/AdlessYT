import 'dart:io';
import 'dart:math';

import 'package:adless_youtube/Types/base_video_controller.dart';
import 'package:adless_youtube/Types/local_controller.dart';
import 'package:adless_youtube/Types/video_source.dart';
import 'package:adless_youtube/Types/youtube_controller.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerProvider extends ChangeNotifier {
  /* Is extended by LocalVideoWrapper and YoutubeVideoWrapper*/
  final ValueNotifier<BaseVideoController?> _controller = ValueNotifier(null);

  /* Whether is YT or Local */
  final ValueNotifier<VideoSource?> _currentSource = ValueNotifier(null);
  final ValueNotifier<bool> _playing = ValueNotifier(true);
  final ValueNotifier<double> _controlOpacity = ValueNotifier(0.0);

  /* Whether or not the Pause, Slider, ... controls are visible or not */
  final ValueNotifier<bool> _showControls = ValueNotifier(false);
  final ValueNotifier<bool?> mainPage = ValueNotifier(null);
  String? _currentLocalPath;
  Video? video;

  ValueNotifier<BaseVideoController?> get controller => _controller;
  ValueNotifier<VideoSource?> get currentSource => _currentSource;
  ValueNotifier<bool> get playing => _playing;
  ValueNotifier<double> get controlOpacityNotifier => _controlOpacity;
  ValueNotifier<bool> get showControlsNotifier => _showControls;
  Video? get currentVideo => video;
  String? get currentLocalPath => _currentLocalPath;

  Future<void> initializeYoutubeVideo(Video vid) async {
    if (video?.id.value != vid.id.value ||
        _currentSource.value != VideoSource.youtube) {
      await _dispose();

      final controller = YoutubePlayerController(
        initialVideoId: vid.id.value,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          hideControls: true,
          enableCaption: true,
          hideThumbnail: false,
        ),
      );

      _controller.value = YoutubeControllerWrapper(controller);
      video = vid;
      _currentSource.value = VideoSource.youtube;
      _playing.value = true;
    }
  }

  Future<void> initializeLocalVideo(Video vid, String filePath) async {
    if (_currentLocalPath == filePath &&
        _currentSource.value == VideoSource.local) {
      return;
    }

    await _dispose();

    _currentLocalPath = filePath;
    _currentSource.value = VideoSource.local;

    video = vid;

    final controller = VideoPlayerController.file(
      File(filePath),
    );

    await controller.initialize();
    _controller.value = LocalControllerWrapper(controller);
    _playing.value = true;
    controller.play();
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
    await _controller.value?.dispose();
    _controller.value = null;
    _currentLocalPath = null;
    _playing.value = false;
  }

  Future<void> setMainPage(bool mPage) async {
    await Future.microtask(() {
      mainPage.value = mPage;
    });
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}

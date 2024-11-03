import 'dart:math';
import 'dart:async';

import 'package:adless_youtube/Types/local_controller.dart';
import 'package:adless_youtube/Types/video_source.dart';
import 'package:adless_youtube/Types/youtube_controller.dart';
import 'package:adless_youtube/Utils/globals.dart';
import 'package:adless_youtube/Utils/theme.dart';
import 'package:adless_youtube/Utils/video_controller.dart';
import 'package:adless_youtube/Utils/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeVideoPage extends StatefulWidget {
  const YoutubeVideoPage({super.key});

  @override
  State<YoutubeVideoPage> createState() => YoutubeVideoPageState();
}

class YoutubeVideoPageState extends State<YoutubeVideoPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    VideoController.videoPage = true;
  }

  void consequtiveTimer(int ms, void Function() func, bool Function() recurse) {
    Timer(Duration(milliseconds: ms), () {
      func();
      if (recurse()) consequtiveTimer(ms, func, recurse);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    bool vertical = Globals.size(context).height > Globals.size(context).width;

    double playerHeight(BuildContext context) =>
        Globals.size(context).width * 9 / 16;

    var videoProvider = context.read<VideoPlayerProvider>();

    return Scaffold(
      backgroundColor: YTTheme.darkGray,
      appBar: vertical && VideoController.videoPage
          ? AppBar(
              backgroundColor: YTTheme.darkGray,
              leading: IconButton(
                onPressed: () {
                  VideoController.videoPage = false;
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: YTTheme.white,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (!videoProvider.showControlsNotifier.value) {
                      consequtiveTimer(250, () {
                        videoProvider.updateControlsVisibility(
                            videoProvider.controlOpacityNotifier.value >= 0.1,
                            videoProvider.controlOpacityNotifier.value - 0.1);
                      },
                          () =>
                              videoProvider.controlOpacityNotifier.value >=
                              0.1);
                    }
                  },
                  child: ValueListenableBuilder(
                    valueListenable: videoProvider.controller,
                    builder: (context, controller, _) {
                      return ValueListenableBuilder(
                          valueListenable: videoProvider.currentSource,
                          builder: (context, source, _) {
                            return source == VideoSource.youtube
                                ? YoutubePlayer(
                                    controller:
                                        (controller as YoutubeControllerWrapper)
                                            .controller)
                                : VideoPlayer(
                                    (controller as LocalControllerWrapper)
                                        .controller);
                          });
                    },
                  ),
                ),
                ValueListenableBuilder<bool>(
                    valueListenable: videoProvider.showControlsNotifier,
                    builder: (context, isVisible, child) {
                      if (!isVisible) return const SizedBox.shrink();
                      return ValueListenableBuilder<double>(
                          valueListenable: videoProvider.controlOpacityNotifier,
                          builder: (context, opacity, child) {
                            return Opacity(
                              opacity: opacity,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          YTTheme.lightGray,
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    width: Globals.size(context).width / 3,
                                    height: playerHeight(context),
                                    child: ValueListenableBuilder(
                                        valueListenable:
                                            videoProvider.currentSource,
                                        builder: (context, source, _) {
                                          return ValueListenableBuilder(
                                              valueListenable:
                                                  videoProvider.controller,
                                              builder:
                                                  (context, controller, _) {
                                                return GestureDetector(
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.replay_10_sharp,
                                                      color: YTTheme.white,
                                                    ),
                                                  ),
                                                  onTap: () async {
                                                    int currPosMiliSec;

                                                    if (source ==
                                                        VideoSource.youtube) {
                                                      currPosMiliSec = (controller
                                                              as YoutubePlayerController)
                                                          .value
                                                          .position
                                                          .inMilliseconds;
                                                    } else if (source ==
                                                        VideoSource.local) {
                                                      currPosMiliSec =
                                                          (await (controller
                                                                      as VideoPlayerController)
                                                                  .position)!
                                                              .inMilliseconds;
                                                    } else {
                                                      return;
                                                    }
                                                    videoProvider.seekTo(
                                                      Duration(
                                                        milliseconds: max(
                                                            currPosMiliSec -
                                                                10000,
                                                            0),
                                                      ),
                                                    );
                                                  },
                                                );
                                              });
                                        }),
                                  ),
                                  Expanded(
                                    child: IconButton(
                                      onPressed: () {
                                        videoProvider.togglePlayPause();
                                      },
                                      icon: ValueListenableBuilder(
                                          valueListenable:
                                              videoProvider.playing,
                                          builder: (context, isPlaying, _) {
                                            return Icon(
                                              isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              size: 64,
                                              color: YTTheme.white,
                                            );
                                          }),
                                    ),
                                  ),
                                  Container(
                                    width: Globals.size(context).width / 3,
                                    height: playerHeight(context),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          YTTheme.lightGray,
                                        ],
                                      ),
                                    ),
                                    child: ValueListenableBuilder(
                                        valueListenable:
                                            videoProvider.currentSource,
                                        builder: (context, source, _) {
                                          return ValueListenableBuilder(
                                              valueListenable:
                                                  videoProvider.controller,
                                              builder:
                                                  (context, controller, _) {
                                                return GestureDetector(
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.forward_10_sharp,
                                                      color: YTTheme.white,
                                                    ),
                                                  ),
                                                  onTap: () async {
                                                    int currPosMiliSec;
                                                    int videoDurationMiliSec;

                                                    if (source ==
                                                        VideoSource.youtube) {
                                                      final control = (controller
                                                          as YoutubePlayerController);
                                                      currPosMiliSec = control
                                                          .value
                                                          .position
                                                          .inMilliseconds;
                                                      videoDurationMiliSec =
                                                          control
                                                              .metadata
                                                              .duration
                                                              .inMilliseconds;
                                                    } else if (source ==
                                                        VideoSource.local) {
                                                      final control = (controller
                                                          as VideoPlayerController);
                                                      currPosMiliSec =
                                                          (await control
                                                                  .position)!
                                                              .inMilliseconds;
                                                      videoDurationMiliSec =
                                                          control.value.duration
                                                              .inMilliseconds;
                                                    } else {
                                                      return;
                                                    }
                                                    videoProvider.seekTo(
                                                      Duration(
                                                        milliseconds: min(
                                                            currPosMiliSec +
                                                                10000,
                                                            videoDurationMiliSec),
                                                      ),
                                                    );
                                                  },
                                                );
                                              });
                                        }),
                                  ),
                                ],
                              ),
                            );
                          });
                    }),
                Positioned(
                  top: 15,
                  left: Globals.size(context).width * 0.1,
                  child: ValueListenableBuilder<bool>(
                      valueListenable: videoProvider.showControlsNotifier,
                      builder: (context, isVisible, _) {
                        return ValueListenableBuilder<double>(
                            valueListenable:
                                videoProvider.controlOpacityNotifier,
                            builder: (context, opacity, _) {
                              return Text(
                                videoProvider.video!.title,
                                style: TextStyle(
                                    color: YTTheme.white.withOpacity(opacity)),
                              );
                            });
                      }),
                ),
                ValueListenableBuilder<bool>(
                    valueListenable: videoProvider.showControlsNotifier,
                    builder: (context, isVisible, _) {
                      return !isVisible
                          ? const SizedBox.shrink()
                          : Positioned(
                              right: Globals.size(context).width * 0.04,
                              child: ValueListenableBuilder<double>(
                                valueListenable:
                                    videoProvider.controlOpacityNotifier,
                                builder: (context, opacity, _) {
                                  return ValueListenableBuilder(
                                      valueListenable:
                                          videoProvider.currentSource,
                                      builder: (context, source, _) {
                                        return ValueListenableBuilder(
                                            valueListenable:
                                                videoProvider.controller,
                                            builder: (context, controller, _) {
                                              return DropdownButton<double>(
                                                underline: const SizedBox(),
                                                icon: Icon(
                                                  Icons.speed,
                                                  color: YTTheme.white
                                                      .withOpacity(opacity),
                                                ),
                                                iconSize: 24,
                                                style: TextStyle(
                                                  color: YTTheme.white
                                                      .withOpacity(opacity),
                                                  textBaseline:
                                                      TextBaseline.alphabetic,
                                                ),
                                                dropdownColor: Colors.black,
                                                value: null,
                                                onChanged: (val) {
                                                  if (source ==
                                                          VideoSource.youtube &&
                                                      (controller as YoutubePlayerController)
                                                              .value
                                                              .playbackRate ==
                                                          val) {
                                                    return;
                                                  } else if (source ==
                                                          VideoSource.local &&
                                                      (controller as YoutubePlayerController)
                                                              .value
                                                              .playbackRate ==
                                                          val) {
                                                    return;
                                                  }
                                                  controller!
                                                      .setPlaybackRate(val!);
                                                },
                                                items: const [
                                                  DropdownMenuItem(
                                                      value: 0.25,
                                                      child: Text("0.25")),
                                                  DropdownMenuItem(
                                                      value: 0.50,
                                                      child: Text("0.50")),
                                                  DropdownMenuItem(
                                                      value: 0.75,
                                                      child: Text("0.75")),
                                                  DropdownMenuItem(
                                                      value: 1.00,
                                                      child: Text("1.00")),
                                                  DropdownMenuItem(
                                                      value: 1.25,
                                                      child: Text("1.25")),
                                                  DropdownMenuItem(
                                                      value: 1.50,
                                                      child: Text("1.50")),
                                                  DropdownMenuItem(
                                                      value: 1.75,
                                                      child: Text("1.75")),
                                                  DropdownMenuItem(
                                                      value: 2.00,
                                                      child: Text("2.00")),
                                                ],
                                              );
                                            });
                                      });
                                },
                              ),
                            );
                    }),
                ValueListenableBuilder(
                    valueListenable: videoProvider.showControlsNotifier,
                    builder: (context, isVisible, _) {
                      return !isVisible
                          ? const SizedBox.shrink()
                          : Positioned(
                              left: 0,
                              right: 0,
                              top: playerHeight(context) -
                                  playerHeight(context) * 0.2,
                              child: ValueListenableBuilder(
                                valueListenable:
                                    VideoController.youtubeController!,
                                builder: (context, value, child) {
                                  return ValueListenableBuilder(
                                      valueListenable:
                                          videoProvider.controlOpacityNotifier,
                                      builder: (context, opacity, _) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              Globals.formatDuration(
                                                  value.position),
                                              style: TextStyle(
                                                  color: YTTheme.white
                                                      .withOpacity(opacity)),
                                            ),
                                            SizedBox(
                                              width:
                                                  Globals.size(context).width *
                                                      0.7,
                                              child: SliderTheme(
                                                  data: SliderThemeData(
                                                    thumbColor: YTTheme.blue
                                                        .withOpacity(opacity),
                                                    thumbShape:
                                                        const RoundSliderThumbShape(
                                                            enabledThumbRadius:
                                                                6),
                                                    overlayShape:
                                                        const RoundSliderOverlayShape(
                                                            overlayRadius: 12),
                                                    activeTrackColor: YTTheme
                                                        .lightGray
                                                        .withOpacity(opacity),
                                                    inactiveTrackColor: YTTheme
                                                        .darkGray
                                                        .withOpacity(opacity),
                                                    overlayColor: YTTheme.blue
                                                        .withOpacity(
                                                            0.5 * opacity),
                                                  ),
                                                  child: Slider(
                                                    value: value
                                                        .position.inMilliseconds
                                                        .toDouble(),
                                                    onChanged: (value) {
                                                      VideoController
                                                          .youtubeController!
                                                          .seekTo(
                                                        Duration(
                                                            milliseconds:
                                                                value.toInt()),
                                                      );
                                                    },
                                                    min: 0,
                                                    max: value.metaData.duration
                                                        .inMilliseconds
                                                        .toDouble(),
                                                  )),
                                            ),
                                            Text(
                                              Globals.formatDuration(
                                                  value.metaData.duration),
                                              style: TextStyle(
                                                  color: YTTheme.white
                                                      .withOpacity(opacity)),
                                            ),
                                          ],
                                        );
                                      });
                                },
                              ),
                            );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

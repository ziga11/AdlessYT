import 'dart:math';
import 'dart:async';

import 'package:adless_youtube/Types/base_video_controller.dart';
import 'package:adless_youtube/Types/local_controller.dart';
import 'package:adless_youtube/Types/video_source.dart';
import 'package:adless_youtube/Types/youtube_controller.dart';
import 'package:adless_youtube/Utils/globals.dart';
import 'package:adless_youtube/Utils/theme.dart';
import 'package:adless_youtube/Utils/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VideoPage extends StatefulWidget {
  static String settings = "/videoPage";
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => VideoPageState();
}

class VideoPageState extends State<VideoPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  DateTime? startTime;
  late final VideoPlayerProvider videoProvider;
  VideoSource? source;
  BaseVideoController? controller;

  void consequtiveTimer(int ms, void Function() func, bool Function() recurse) {
    Timer(Duration(milliseconds: ms), () {
      func();
      if (recurse()) consequtiveTimer(ms, func, recurse);
    });
  }

  @override
  void initState() {
    super.initState();
    videoProvider = context.read<VideoPlayerProvider>();
    source = videoProvider.currentSource.value;
    controller = videoProvider.controller.value;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    bool vertical = Globals.size(context).height > Globals.size(context).width;

    double playerHeight(BuildContext context) =>
        Globals.size(context).width * 9 / 16;

    void showControls() {
      DateTime start = DateTime.now();
      startTime = start;

      videoProvider.updateControlsVisibility(true, 1.0);

      Timer(const Duration(milliseconds: 1500), () {
        consequtiveTimer(75, () {
          videoProvider.updateControlsVisibility(
              videoProvider.controlOpacityNotifier.value >= 0.11,
              videoProvider.controlOpacityNotifier.value - 0.1);
        },
            () =>
                videoProvider.controlOpacityNotifier.value >= 0.1 &&
                startTime == start);
      });
    }

    Widget miniPlayPause() {
      return ValueListenableBuilder(
          valueListenable: videoProvider.playing,
          builder: (context, isPlaying, _) {
            return IconButton(
              onPressed: () {
                videoProvider.togglePlayPause();
              },
              color: YTTheme.white,
              icon: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: YTTheme.white,
              ),
            );
          });
    }

    Widget closeButton() {
      return IconButton(
          onPressed: () async {
            if (videoProvider.playing.value) {
              await videoProvider.togglePlayPause();
            }
            await videoProvider.disposeVideo();
          },
          icon: Icon(
            Icons.close_sharp,
            color: YTTheme.white,
          ));
    }

    Widget title() {
      return Positioned(
        top: 15,
        left: Globals.size(context).width * 0.1,
        child: ValueListenableBuilder<bool>(
            valueListenable: videoProvider.showControlsNotifier,
            builder: (context, isVisible, _) {
              return ValueListenableBuilder<double>(
                  valueListenable: videoProvider.controlOpacityNotifier,
                  builder: (context, opacity, _) {
                    return Text(
                      videoProvider.currentVideo!.title,
                      style:
                          TextStyle(color: YTTheme.white.withOpacity(opacity)),
                    );
                  });
            }),
      );
    }

    Widget mainControls() {
      return ValueListenableBuilder<bool>(
          valueListenable: videoProvider.showControlsNotifier,
          builder: (context, isVisible, child) {
            if (!isVisible) {
              return const SizedBox.shrink();
            }
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
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Icon(
                                Icons.replay_10_sharp,
                                color: YTTheme.white,
                              ),
                            ),
                            onTap: () async {
                              int currPosMiliSec;
                              showControls();
                              if (source == VideoSource.youtube) {
                                final control =
                                    (controller as YoutubeControllerWrapper)
                                        .controller;
                                currPosMiliSec =
                                    control.value.position.inMilliseconds;
                              } else if (source == VideoSource.local) {
                                final control =
                                    (controller as LocalControllerWrapper)
                                        .controller;
                                currPosMiliSec =
                                    (await control.position)!.inMilliseconds;
                              } else {
                                return;
                              }
                              videoProvider.seekTo(
                                Duration(
                                  milliseconds: max(currPosMiliSec - 10000, 0),
                                ),
                              );
                            },
                          ),
                        ),
                        Expanded(
                          child: IconButton(
                            onPressed: () {
                              videoProvider.togglePlayPause();
                            },
                            icon: ValueListenableBuilder(
                                valueListenable: videoProvider.playing,
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
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Icon(
                                Icons.forward_10_sharp,
                                color: YTTheme.white,
                              ),
                            ),
                            onTap: () async {
                              int currPosMiliSec;
                              int videoDurationMiliSec;
                              showControls();

                              if (source == VideoSource.youtube) {
                                final control =
                                    (controller as YoutubeControllerWrapper)
                                        .controller;
                                currPosMiliSec =
                                    control.value.position.inMilliseconds;
                                videoDurationMiliSec =
                                    control.metadata.duration.inMilliseconds;
                              } else if (source == VideoSource.local) {
                                final control =
                                    (controller as LocalControllerWrapper)
                                        .controller;
                                currPosMiliSec =
                                    (await control.position)!.inMilliseconds;
                                videoDurationMiliSec =
                                    control.value.duration.inMilliseconds;
                              } else {
                                return;
                              }
                              videoProvider.seekTo(
                                Duration(
                                  milliseconds: min(currPosMiliSec + 10000,
                                      videoDurationMiliSec),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                });
          });
    }

    Widget playbackSpeed() {
      return ValueListenableBuilder<bool>(
          valueListenable: videoProvider.showControlsNotifier,
          builder: (context, isVisible, _) {
            return !isVisible
                ? const SizedBox.shrink()
                : Positioned(
                    right: Globals.size(context).width * 0.04,
                    child: ValueListenableBuilder<double>(
                      valueListenable: videoProvider.controlOpacityNotifier,
                      builder: (context, opacity, _) {
                        return DropdownButton<double>(
                          onTap: () {
                            startTime = null;
                            videoProvider.updateControlsVisibility(true, 1);
                          },
                          underline: const SizedBox(),
                          icon: Icon(
                            Icons.speed,
                            color: YTTheme.white.withOpacity(opacity),
                          ),
                          iconSize: 24,
                          style: TextStyle(
                            color: YTTheme.white.withOpacity(opacity),
                            textBaseline: TextBaseline.alphabetic,
                          ),
                          dropdownColor: Colors.black,
                          value: null,
                          onChanged: (val) {
                            if (source == VideoSource.youtube &&
                                (controller as YoutubeControllerWrapper)
                                        .controller
                                        .value
                                        .playbackRate ==
                                    val) {
                              return;
                            } else if (source == VideoSource.local &&
                                (controller as YoutubeControllerWrapper)
                                        .controller
                                        .value
                                        .playbackRate ==
                                    val) {
                              return;
                            }
                            controller!.setPlaybackRate(val!);
                            showControls();
                          },
                          items: const [
                            DropdownMenuItem(value: 0.25, child: Text("0.25")),
                            DropdownMenuItem(value: 0.50, child: Text("0.50")),
                            DropdownMenuItem(value: 0.75, child: Text("0.75")),
                            DropdownMenuItem(value: 1.00, child: Text("1.00")),
                            DropdownMenuItem(value: 1.25, child: Text("1.25")),
                            DropdownMenuItem(value: 1.50, child: Text("1.50")),
                            DropdownMenuItem(value: 1.75, child: Text("1.75")),
                            DropdownMenuItem(value: 2.00, child: Text("2.00")),
                          ],
                        );
                      },
                    ),
                  );
          });
    }

    Widget durationSlider() {
      return ValueListenableBuilder(
          valueListenable: videoProvider.showControlsNotifier,
          builder: (context, isVisible, _) {
            return !isVisible
                ? const SizedBox.shrink()
                : Positioned(
                    left: 0,
                    right: 0,
                    top: playerHeight(context) - playerHeight(context) * 0.2,
                    child: ValueListenableBuilder(
                      valueListenable:
                          (controller as YoutubeControllerWrapper).controller,
                      builder: (context, value, child) {
                        return ValueListenableBuilder(
                            valueListenable:
                                videoProvider.controlOpacityNotifier,
                            builder: (context, opacity, _) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    Globals.formatDuration(value.position),
                                    style: TextStyle(
                                        color:
                                            YTTheme.white.withOpacity(opacity)),
                                  ),
                                  SizedBox(
                                    width: Globals.size(context).width * 0.7,
                                    child: SliderTheme(
                                        data: SliderThemeData(
                                          thumbColor:
                                              YTTheme.blue.withOpacity(opacity),
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                  enabledThumbRadius: 6),
                                          overlayShape:
                                              const RoundSliderOverlayShape(
                                                  overlayRadius: 12),
                                          activeTrackColor: YTTheme.lightGray
                                              .withOpacity(opacity),
                                          inactiveTrackColor: YTTheme.darkGray
                                              .withOpacity(opacity),
                                          overlayColor: YTTheme.blue
                                              .withOpacity(0.5 * opacity),
                                        ),
                                        child: Slider(
                                          value: value.position.inMilliseconds
                                              .toDouble(),
                                          onChanged: (value) {
                                            videoProvider
                                                .updateControlsVisibility(
                                                    true, 1.0);
                                            videoProvider.seekTo(Duration(
                                                milliseconds: value.toInt()));
                                          },
                                          min: 0,
                                          max: value
                                              .metaData.duration.inMilliseconds
                                              .toDouble(),
                                        )),
                                  ),
                                  Text(
                                    Globals.formatDuration(
                                        value.metaData.duration),
                                    style: TextStyle(
                                        color:
                                            YTTheme.white.withOpacity(opacity)),
                                  ),
                                ],
                              );
                            });
                      },
                    ),
                  );
          });
    }

    return ValueListenableBuilder(
        valueListenable: videoProvider.mainPage,
        builder: (context, mainPage, _) {
          void onControllerReady() {
            if ((controller as YoutubeControllerWrapper)
                .controller
                .value
                .isReady) {
              (controller as YoutubeControllerWrapper).controller.play();
              (controller as YoutubeControllerWrapper)
                  .controller
                  .removeListener(onControllerReady);
            }
          }

          (controller as YoutubeControllerWrapper)
              .controller
              .addListener(onControllerReady);
          return Scaffold(
            backgroundColor: YTTheme.darkGray,
            appBar: vertical && mainPage!
                ? AppBar(
                    backgroundColor: YTTheme.darkGray,
                    leading: IconButton(
                      onPressed: () {
                        videoProvider.setMainPage(false);
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
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: () {
                                if (videoProvider.mainPage.value!) {
                                  showControls();
                                } else {
                                  videoProvider.setMainPage(true);
                                  if (videoProvider.getLastRouteArgs != null) {
                                    videoProvider.getLastRouteArgs!();
                                  }
                                }
                              },
                              child: videoProvider.activePlayer,
                            ),
                          ),
                          mainPage!
                              ? const SizedBox.shrink()
                              : Expanded(child: miniPlayPause()),
                          mainPage
                              ? const SizedBox.shrink()
                              : Expanded(child: closeButton()),
                        ],
                      ),
                      mainPage ? title() : const SizedBox.shrink(),
                      mainPage ? mainControls() : const SizedBox.shrink(),
                      mainPage ? playbackSpeed() : const SizedBox.shrink(),
                      mainPage ? durationSlider() : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }
}
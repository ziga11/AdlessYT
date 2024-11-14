import 'package:adless_youtube/Fetch/youtube_api.dart';
import 'package:adless_youtube/Fetch/youtube_explode.dart';
import 'package:adless_youtube/Pages/playlist_tile.dart';
import 'package:adless_youtube/Pages/video_tile.dart';
import 'package:adless_youtube/Utils/globals.dart';
import 'package:adless_youtube/Utils/theme.dart';
import 'package:adless_youtube/Utils/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class ChannelPage extends StatefulWidget {
  static const String settings = "/channel";

  const ChannelPage({super.key});

  @override
  State<ChannelPage> createState() => _ChannelPageState();
}

class _ChannelPageState extends State<ChannelPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController videoScrollController = ScrollController();
  final ScrollController playlistScrollController = ScrollController();
  final ScrollController shortsScrollController = ScrollController();
  late final VideoPlayerProvider videoProvider;
  final YoutubeFetch youtubeFetch = YoutubeFetch();
  int _currentPageIndex = 0;
  Channel? channel;
  List<Video> videos = [];
  List<Video> shorts = [];
  List<Playlist> playlists = [];
  ChannelUploadsList? currVideoBatch;
  ChannelUploadsList? currShortsBatch;
  Map<String, bool> fetchedAll = {
    "videos": false,
    "playlists": false,
    "shorts": false
  };

  @override
  bool get wantKeepAlive => true;

  Widget bodyUI(Channel channel) {
    return Container(
      color: YTTheme.darkGray,
      child: Column(
        children: [
          Container(
            width: Globals.size(context).width * 0.9,
            height: Globals.size(context).width * 0.4,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
            child: Stack(
              children: [
                if (channel.bannerUrl.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(channel.bannerUrl),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 30, 10, 30),
                  child: Row(
                    children: [
                      ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.network(channel.logoUrl)),
                      const SizedBox(width: 20),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.title,
                            style: TextStyle(color: YTTheme.white),
                          ),
                          Text(
                            "${channel.subscribersCount} subscribers",
                            style: TextStyle(
                                color: YTTheme.white.withOpacity(0.75)),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
                color: YTTheme.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2.0, left: 15, right: 15),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                        onPressed: () => _switchPage(0),
                        child: Column(
                          children: [
                            Text(
                              "Videos",
                              style: TextStyle(
                                color: _currentPageIndex == 0
                                    ? YTTheme.white
                                    : YTTheme.lightGray,
                              ),
                            ),
                            Divider(
                              color: _currentPageIndex == 0
                                  ? YTTheme.white
                                  : YTTheme.lightGray,
                            )
                          ],
                        )),
                  ),
                  Expanded(
                    child: TextButton(
                        onPressed: () => _switchPage(1),
                        child: Column(
                          children: [
                            Text(
                              "Shorts",
                              style: TextStyle(
                                color: _currentPageIndex == 1
                                    ? YTTheme.white
                                    : YTTheme.lightGray,
                              ),
                            ),
                            Divider(
                              color: _currentPageIndex == 1
                                  ? YTTheme.white
                                  : YTTheme.lightGray,
                            )
                          ],
                        )),
                  ),
                  Expanded(
                    child: TextButton(
                        onPressed: () => _switchPage(2),
                        child: Column(
                          children: [
                            Text(
                              "Playlists",
                              style: TextStyle(
                                color: _currentPageIndex == 2
                                    ? YTTheme.white
                                    : YTTheme.lightGray,
                              ),
                            ),
                            Divider(
                              color: _currentPageIndex == 2
                                  ? YTTheme.white
                                  : YTTheme.lightGray,
                            )
                          ],
                        )),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: IndexedStack(
              index: _currentPageIndex,
              children: [
                _buildLazyScrollView(
                  controller: videoScrollController,
                  items: videos,
                  type: "videos",
                  onLoadMore: nextVideoBatch,
                  itemBuilder: (context, index) => VideoListTile(
                      video: videos[index],
                      onTap: () async {
                        await videoProvider
                            .initializeYoutubeVideo([videos[index]]);
                      }),
                ),
                _buildLazyScrollView(
                  controller: shortsScrollController,
                  items: shorts,
                  type: "shorts",
                  onLoadMore: nextShortsBatch,
                  itemBuilder: (context, index) => VideoListTile(
                      video: shorts[index],
                      onTap: () async {
                        await videoProvider
                            .initializeYoutubeVideo([shorts[index]]);
                      }),
                ),
                _buildLazyScrollView(
                  controller: playlistScrollController,
                  items: playlists,
                  type: "playlists",
                  onLoadMore: nextPlaylistBatch,
                  itemBuilder: (context, index) => PlaylistListTile(
                    playlist: playlists[index],
                    onTap: () async {
                      await videoProvider.initializeYoutubeVideo(
                        await (await getPlaylistVideos(playlists[index]))
                            .toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // PageView
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? channelId = args != null ? args["channelId"] : null;

    return Scaffold(
      backgroundColor: YTTheme.darkGray,
      appBar: AppBar(
        backgroundColor: YTTheme.lightGray,
        leading: const BackButton(
          color: Colors.white,
        ),
        actions: [
          if (channelId == null)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: _handleSignOut,
                icon: Icon(
                  Icons.logout,
                  color: YTTheme.white,
                ),
              ),
            )
        ],
      ),
      body: FutureBuilder(
        future: channelId != null
            ? getChannel(channelId)
            : youtubeFetch.fetchMyYouTubeChannel(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error occurred ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No data found"));
          }

          if (channel == null) {
            channel = snapshot.data!;
            if (channel == null) {
              return const Text("No Channel Provided");
            }
            nextVideoBatch();
          }

          return bodyUI(channel!);
        },
      ),
    );
  }

  @override
  void dispose() {
    videoScrollController.dispose();
    playlistScrollController.dispose();
    shortsScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setupScrollControllers();
    videoProvider = context.read<VideoPlayerProvider>();
    videoProvider.getLastRouteArgs = () {
      videoProvider.lastRoute = ChannelPage.settings;
      videoProvider.lastRouteArgs = {
        "fetchedAll": fetchedAll,
        "videos": videos,
        "shorts": shorts,
        "playlists": playlists,
        "videosControllerPos": videoScrollController.position.pixels,
        "shortsControllerPos": shortsScrollController.position.pixels,
        "playlistsControllerPos": playlistScrollController.position.pixels
      };
    };
  }

  Future<void> nextPlaylistBatch() async {
    try {
      if (fetchedAll["playlists"] == true) return;
      List<Playlist> playlistBatch = (await youtubeFetch.fetchChannelPlaylists(
              channel!.id.value,
              prefix: playlists.length,
              batchSize: 50))
          .toList();
      if (playlistBatch.length < 50 || playlistBatch.isEmpty) {
        fetchedAll["playlists"] = true;
      }
      if (mounted) {
        setState(() {
          playlists.addAll(playlistBatch);
        });
      }
    } catch (e) {
      fetchedAll["playlists"] = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load playlists: ${e.toString()}')),
        );
      }
      print(e);
    }
  }

  Future<void> nextShortsBatch() async {
    try {
      if (fetchedAll["shorts"] == true) return;
      ChannelUploadsList? newShortsBatch =
          await getChannelShorts(channel!, uploadList: currShortsBatch);
      if (newShortsBatch == null) {
        fetchedAll["shorts"] = true;
        return;
      }
      currShortsBatch = newShortsBatch;
      if (mounted) {
        setState(() {
          shorts.addAll(currShortsBatch as List<Video>);
        });
      }
    } catch (e) {
      fetchedAll["shorts"] = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load shorts : ${e.toString()}')),
        );
      }
      print(e);
    }
  }

  Future<void> nextVideoBatch() async {
    try {
      if (fetchedAll["videos"] == true) return;
      ChannelUploadsList? newVideoBatch =
          await getChannelVideos(channel!, uploadList: currVideoBatch);
      if (newVideoBatch == null) {
        fetchedAll["videos"] = true;
        return;
      }
      currVideoBatch = newVideoBatch;
      if (mounted) {
        setState(() {
          videos.addAll(currVideoBatch as List<Video>);
        });
      }
    } catch (e) {
      fetchedAll["videos"] = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load videos: ${e.toString()}')),
        );
      }
      print(e);
    }
  }

  Widget _buildLazyScrollView({
    ValueKey? key,
    required ScrollController controller,
    required List items,
    required Widget Function(BuildContext, int) itemBuilder,
    required String type,
    required Future<void> Function() onLoadMore,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Text("No ${type}s"),
      );
    }

    return CustomScrollView(
      key: key,
      controller: controller,
      slivers: [
        Builder(builder: (context) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= items.length) {
                  if (fetchedAll[type] == true) {
                    return null;
                  }
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return itemBuilder(context, index);
              },
              childCount: fetchedAll[type]! ? items.length : items.length + 1,
            ),
          );
        }),
      ],
    );
  }

  int _getIndexByType(String type) {
    switch (type) {
      case "videos":
        return 0;
      case "shorts":
        return 1;
      case "playlists":
        return 2;
      default:
        return 0;
    }
  }

  Future<void> _handleSignOut() async {
    await Globals.googleSignIn.disconnect();
    setState(() {
      Globals.googleUser = null;
    });
  }

  void _setupScrollControllers() {
    void setupController(ScrollController controller, String type,
        Future<void> Function() onLoadMore) {
      controller.addListener(() {
        if (_currentPageIndex != _getIndexByType(type)) return;

        ScrollPosition pos = controller.position;
        if (pos.pixels < pos.maxScrollExtent - 100 ||
            fetchedAll[type] == true) {
          return;
        }
        onLoadMore();
      });
    }

    setupController(videoScrollController, "videos", nextVideoBatch);
    setupController(shortsScrollController, "shorts", nextShortsBatch);
    setupController(playlistScrollController, "playlists", nextPlaylistBatch);
  }

  void _switchPage(int index) {
    if (_currentPageIndex == index) return;

    switch (index) {
      case 0:
        if (videos.isEmpty) {
          nextVideoBatch();
        }
        break;
      case 1:
        if (shorts.isEmpty) {
          nextShortsBatch();
        }
        break;
      case 2:
        if (playlists.isEmpty) {
          nextPlaylistBatch();
        }
        break;
      default:
    }

    setState(() {
      _currentPageIndex = index;
    });
  }
}

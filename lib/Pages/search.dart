import 'dart:collection';

import 'package:adless_youtube/Fetch/youtube_explode.dart';
import 'package:adless_youtube/Utils/globals.dart';
import 'package:adless_youtube/Utils/theme.dart';
import 'package:adless_youtube/Utils/video_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchPage extends StatefulWidget {
  static const String settings = "/search";

  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with AutomaticKeepAliveClientMixin {
  SearchList? searchList;
  final HashMap<String, Video> videoMemoization = HashMap();
  ScrollController scrollController = ScrollController();
  late final VideoPlayerProvider videoProvider;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    videoProvider = context.read<VideoPlayerProvider>();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.only(left: 15, right: 15, top: 30, bottom: 20),
          color: YTTheme.lightGray,
          child: TextFormField(
            cursorColor: YTTheme.white,
            style: TextStyle(color: YTTheme.white),
            controller: Globals.searchController,
            decoration: InputDecoration(
              labelText: "Search",
              hintText: "Search Query...",
              labelStyle: TextStyle(color: YTTheme.white),
              hintStyle: TextStyle(color: YTTheme.lightGray),
              suffixIcon: IconButton(
                  onPressed: () async {
                    searchList =
                        await getSearchResults(Globals.searchController.text);
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.search_rounded,
                    color: YTTheme.white,
                  )),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: YTTheme.orange, width: 3)),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: YTTheme.orange, width: 3)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: YTTheme.orange, width: 4)),
            ),
          ),
        ),
        if (searchList != null)
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemBuilder: (context, index) {
                final entity = searchList![index];
                if (entity is SearchVideo) {
                  return video(entity, size);
                } else if (entity is SearchPlaylist) {
                  return playlist(entity, size);
                } else if (entity is SearchChannel) {
                  return channel(entity, size);
                }
                return Container();
              },
              itemCount: searchList!.length,
            ),
          )
      ],
    );
  }

  Widget channel(SearchChannel channel, Size size) {
    String thumbnail;
    try {
      thumbnail = channel.thumbnails.nonNulls.first.url.toString();
    } catch (e) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: YTTheme.lightGray,
        width: 0.9 * size.width,
        height: 0.15 * size.height,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(thumbnail)),
              ),
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Text(
                  channel.name,
                  style: TextStyle(
                      color: YTTheme.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
                ),
              ),
            ))
          ],
        ),
      ),
    );
  }

  Widget playlist(SearchPlaylist playlist, Size size) {
    String? thumbnail;
    Video? video;
    if (videoMemoization.containsKey(playlist.id.value)) {
      video = videoMemoization[playlist.id.value];
    } else if (playlist.thumbnails.nonNulls.isNotEmpty) {
      thumbnail = playlist.thumbnails.nonNulls.first.url.toString();
    }

    Widget videoUi() {
      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                    thumbnail ?? video!.thumbnails.standardResUrl),
              ),
            ),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.all(10),
            child: Center(
              child: Text(
                playlist.title,
                style: TextStyle(
                    color: YTTheme.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 18),
              ),
            ),
          ))
        ],
      );
    }

    return Container(
      color: YTTheme.lightGray,
      width: 0.9 * size.width,
      height: 0.15 * size.height,
      child: thumbnail != null
          ? videoUi()
          : FutureBuilder<Stream<Video>>(
              future: getPlaylistVideos(playlist.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading videos'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No videos found'));
                }

                return StreamBuilder<Video>(
                  stream: snapshot.data,
                  builder: (context, videoSnapshot) {
                    if (videoSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (videoSnapshot.hasError) {
                      return const Center(child: Text('Error loading video'));
                    }
                    if (!videoSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    video = videoSnapshot.data!;
                    videoMemoization[video!.id.value] = video!;
                    return videoUi();
                  },
                );
              },
            ),
    );
  }

  Widget video(SearchVideo video, Size size) {
    String thumbnail;
    try {
      thumbnail = video.thumbnails.nonNulls.first.url.toString();
    } catch (e) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () async {
          try {
            final vid = await getVideo(video.id.value);
            if (!mounted) return;

            print([vid]);
            await videoProvider.initializeYoutubeVideo([vid]);
          } catch (e) {
            if (!mounted) return;
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load video: ${e.toString()}')),
            );
          }
        },
        child: Container(
          width: 0.9 * size.width,
          height: 0.15 * size.height,
          decoration: BoxDecoration(
              color: YTTheme.lightGray, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(thumbnail),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Text(
                          video.duration,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: YTTheme.white,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          color: YTTheme.white, fontWeight: FontWeight.w600),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        video.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: TextStyle(color: YTTheme.orange),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          Globals.formatNumber(video.viewCount),
                          style: TextStyle(color: YTTheme.white),
                        ),
                        const Spacer(),
                        Text(
                          video.uploadDate ?? "",
                          style: TextStyle(color: YTTheme.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }
}


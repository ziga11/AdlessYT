import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:adless_youtube/Utils/globals.dart';

Future<Channel> getChannel(dynamic channelId) async =>
    Globals.youtubeExplode.channels.get(channelId);

Future<SearchList?> getSearchResults(String query,
        {SearchFilter? filter}) async =>
    (Globals.youtubeExplode.search
        .searchContent(query, filter: filter ?? const SearchFilter('')));

Future<Video> getVideo(String videoId) async =>
    Globals.youtubeExplode.videos.get(videoId);

Future<Playlist> getPlaylist(dynamic playlistId) async =>
    Globals.youtubeExplode.playlists.get(playlistId);

Future<Stream<Video>> getPlaylistVideos(dynamic playlistId) async =>
    Globals.youtubeExplode.playlists.getVideos(playlistId);

Future<RelatedVideosList?> getRelatedVideos(Video video) async =>
    await Globals.youtubeExplode.videos.getRelatedVideos(video);

Future<ChannelUploadsList?> getChannelVideos(Channel channel,
        {ChannelUploadsList? uploadList}) async =>
    uploadList != null
        ? uploadList.nextPage()
        : Globals.youtubeExplode.channels.getUploadsFromPage(channel.id);

Future<ChannelUploadsList?> getChannelShorts(Channel channel,
        {ChannelUploadsList? uploadList}) async =>
    uploadList != null
        ? uploadList.nextPage()
        : Globals.youtubeExplode.channels
            .getUploadsFromPage(channel.id, videoType: VideoType.shorts);

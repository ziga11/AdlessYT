import 'dart:io';

import 'package:adless_youtube/Types/downloaded.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:adless_youtube/Utils/globals.dart';
import "package:http/http.dart" as http;
import 'package:path_provider/path_provider.dart';

Future<Channel> getChannel(dynamic channelId) async =>
    await Globals.youtubeExplode.channels.get(channelId);

Future<SearchList?> getSearchResults(String query,
        {SearchFilter? filter}) async =>
    await Globals.youtubeExplode.search
        .searchContent(query, filter: filter ?? const SearchFilter(''));

Future<Video> getVideo(String videoId) async =>
    await Globals.youtubeExplode.videos.get(videoId);

Future<Playlist> getPlaylist(dynamic playlistId) async =>
    await Globals.youtubeExplode.playlists.get(playlistId);

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

Future<void> downloadVideo(Video video, bool audio) async {
  var status = await Permission.storage.request();
  if (!status.isGranted) return;
  Directory? storageDir = await getStorageDir();
  if (storageDir == null) return;

  var thumbnailUrl = video.thumbnails.highResUrl;
  Directory thumbnailDir = Directory('${storageDir.path}/Downloads/Thumbnails');
  if (!await thumbnailDir.exists()) {
    await thumbnailDir.create(recursive: true);
  }

  String downloadDirPath = audio
      ? '${storageDir.path}/Downloads/Music'
      : '${storageDir.path}/Downloads/Videos';
  Directory downloadDir = Directory(downloadDirPath);
  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }
  File thumbnailFile = File("${thumbnailDir.path}/${video.id.value}.png");
  if (!(await thumbnailFile.exists())) {
    await http.get(Uri.parse(thumbnailUrl)).then((response) {
      thumbnailFile.writeAsBytesSync(response.bodyBytes);
    });
  }

  StreamClient streamClient = Globals.youtubeExplode.videos.streamsClient;
  StreamManifest manifest = await streamClient.getManifest(video.id.value);

  if (audio) {
    var audioStream = manifest.audioOnly.withHighestBitrate();
    String extension = audioStream.container.name.toLowerCase();

    File file = File("${downloadDir.path}/${video.id.value}.$extension");
    var fileStream = file.openWrite();

    var stream = streamClient.get(audioStream);
    await stream.pipe(fileStream);

    await fileStream.flush();
    await fileStream.close();
  } else {
    File file = File("${downloadDir.path}/${video.id.value}.mp4");
    var fileStream = file.openWrite();

    var videoStream = streamClient.get(manifest.muxed.withHighestBitrate());
    await videoStream.pipe(fileStream);

    await fileStream.flush();
    await fileStream.close();
  }
}

Future<Directory?> getStorageDir() async => Platform.isAndroid
    ? getExternalStorageDirectory()
    : getApplicationDocumentsDirectory();

Future<Downloaded> isDownloaded(Video video) async {
  String videoId = video.id.value;
  Directory? baseDir;
  if (Platform.isAndroid) {
    baseDir = await getExternalStorageDirectory(); // Android
  } else if (Platform.isIOS) {
    baseDir = await getApplicationDocumentsDirectory(); // iOS
  }

  if (baseDir == null) {
    return Downloaded.no;
  }
  Directory audioDir = Directory('${baseDir.path}/Downloads/Music');
  Directory videoDir = Directory('${baseDir.path}/Downloads/Videos');
  if (!(await audioDir.exists()) && !(await videoDir.exists())) {
    return Downloaded.no;
  }

  bool audioExists = false;
  for (var audio in (await audioDir.list().toList())) {
    String vidId = audio.path.substring(0, audio.path.lastIndexOf("."));
    if (vidId == videoId) {
      audioExists = true;
      break;
    }
  }

  for (var video in (await videoDir.list().toList())) {
    String vidId = video.path.substring(0, video.path.lastIndexOf("."));
    if (vidId == videoId) {
      return audioExists ? Downloaded.both : Downloaded.video;
    }
  }

  return audioExists ? Downloaded.audio : Downloaded.no;
}

Future<void> deleteVideo(Video video, bool audio, bool both) async {
  Directory? storageDir = await getStorageDir();
  if (storageDir == null) return;

  String audioDirPath = '${storageDir.path}/Downloads/Music';
  String videoDirPath = '${storageDir.path}/Downloads/Videos';

  File thumbnail =
      File("${storageDir.path}/Downloads/Thumbnails/${video.id.value}.png");
  if (await thumbnail.exists() && !both) {
    await thumbnail.delete();
  }

  if (audio) {
    final extensions = ['m4a', 'webm'];
    for (var ext in extensions) {
      File file = File("$audioDirPath/${video.id.value}.$ext");
      if (await file.exists()) {
        await file.delete();
        break;
      }
    }
  } else {
    File file = File("$videoDirPath/${video.id.value}.mp4");
    if (await file.exists()) {
      await file.delete();
    }
  }
}

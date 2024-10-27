import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'dart:convert';

class YoutubeFetch {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  Future<Channel?> fetchMyYouTubeChannel() async {
    const storage = FlutterSecureStorage();
    String? accessToken = (await storage.read(key: "youtubeToken"));
    if (accessToken == null) return null;
    const url =
        'https://www.googleapis.com/youtube/v3/channels?mine=true&part=snippet,contentDetails,statistics,brandingSettings';
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode != 200) {
      print('Failed to fetch channel info: ${response.body}');
      print(response.body);
      return null;
    }

    final data = json.decode(response.body)['items'][0];

    /*
  {kind: youtube#channel, etag: 1IF-jAtiE_50_qBZAAtDw6K9pAs, id: UCjF8Vru8JlUklOYDfiXLV6Q, 
  snippet: {title: Mr Ziga, description: , customUrl: @ziga1122, publishedAt: 2011-04-13T15:50:58Z,
  thumbnails: {
    default:{url: https://yt3.ggpht.com/ytc/AIdro_mOhX3c9VkWIsmNdOuPlFkouW7u0khpXIEKmyHTb48-OjA=s88-c-k-c0x00ffffff-no-rj, width: 88, height: 88},
    medium: {url: https://yt3.ggpht.com/ytc/AIdro_mOhX3c9VkWIsmNdOuPlFkouW7u0khpXIEKmyHTb48-OjA=s240-c-k-c0x00ffffff-no-rj, width: 240, height: 240},
    high: {url: https://yt3.ggpht.com/ytc/AIdro_mOhX3c9VkWIsmNdOuPlFkouW7u0khpXIEKmyHTb48-OjA=s800-c-k-c0x00ffffff-no-rj, width: 800, height: 800}
  },
  localized: {title: Mr Ziga, description: }},
  contentDetails: {relatedPlaylists: {likes: LL, uploads: UUjF8Vru8JlUklOYDfiXLV6Q}},
  statistics: {viewCount: 50259, subscriberCount: 47, hiddenSubscriberCount: false, videoCount: 8}, brandingSettings: {channel: {title: Mr Ziga}}}
*/

    Map<String, dynamic> thumbnails =
        data['snippet']['thumbnails'] as Map<String, dynamic>;
    Map<String, dynamic> brandingSettings =
        data['brandingSettings'] as Map<String, dynamic>;

    String id = data["id"];
    String title = data['snippet']['title'];
    String logo = thumbnails.containsKey('high')
        ? thumbnails['high']['url']
        : thumbnails['default']['url'];
    String banner = brandingSettings.containsKey('image')
        ? brandingSettings['image']['bannerMobileImageUrl']
        : "";

    int? subCount = int.tryParse(data['statistics']['subscriberCount']);
    return Channel(ChannelId(id), title, logo, banner, subCount);
  }

  static Future<String?> createPlaylist({
    required String title,
    String? description,
    bool isPrivate = false,
  }) async {
    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: "youtubeToken");

      if (accessToken == null) {
        print('No access token found');
        return null;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/playlists?part=snippet,status'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'snippet': {
            'title': title,
            'description': description ?? '',
          },
          'status': {'privacyStatus': isPrivate ? 'private' : 'public'}
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final playlistId = data['id'];
        print('Successfully created playlist: $playlistId');
        return playlistId;
      } else {
        print('Failed to create playlist: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating playlist: $e');
      return null;
    }
  }

  static Future<bool> addVideoToPlaylist({
    required String playlistId,
    required String videoId,
  }) async {
    try {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: "youtubeToken");

      if (accessToken == null) {
        print('No access token found');
        return false;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/playlistItems?part=snippet'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'snippet': {
            'playlistId': playlistId,
            'resourceId': {
              'kind': 'youtube#video',
              'videoId': videoId,
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        print('Successfully added video to playlist');
        return true;
      } else {
        print('Failed to add video to playlist: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error adding video to playlist: $e');
      return false;
    }
  }

  Future<List<Playlist>> fetchChannelPlaylists(
    String channelId, {
    int prefix = 0,
    int batchSize = 50,
  }) async {
    const storage = FlutterSecureStorage();
    String? accessToken = await storage.read(key: "youtubeToken");
    if (accessToken == null) return [];

    List<Playlist> playlists = [];
    String? pageToken;
    bool hasMorePages = true;
    int processedItems = 0;
    int remainingItemsToSkip = prefix;

    while (hasMorePages && processedItems < prefix + batchSize) {
      final url =
          Uri.parse('https://www.googleapis.com/youtube/v3/playlists').replace(
        queryParameters: {
          'channelId': channelId,
          'part': 'snippet,contentDetails,status',
          'maxResults': '$batchSize',
          if (pageToken != null) 'pageToken': pageToken,
        },
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        print('Failed to fetch playlists: ${response.body}');
        break;
      }

      final data = json.decode(response.body);
      final items = data['items'] as List;

      for (final item in items) {
        if (remainingItemsToSkip > 0) {
          remainingItemsToSkip--;
          continue;
        }
        if (processedItems >= prefix + batchSize) {
          break;
        }

        final snippet = item['snippet'];
        final contentDetails = item['contentDetails'];
        final thumbnailSplit =
            snippet['thumbnails']['default'].toString().split("/");
        final thumbnailId = thumbnailSplit[thumbnailSplit.length - 2];

        playlists.add(Playlist(
          PlaylistId(item['id']),
          snippet['title'],
          snippet['channelTitle'],
          snippet['description'],
          ThumbnailSet(thumbnailId),
          const Engagement(0, null, null),
          contentDetails['itemCount'],
        ));

        processedItems++;
      }

      pageToken = data['nextPageToken'];
      hasMorePages = pageToken != null;
    }

    return playlists;
  }
}

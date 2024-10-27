import 'package:sqflite/sqflite.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class Playlist {
  int playlistId;
  String title;
  List<Video> videos = [];
  DateTime date = DateTime.now();

  Playlist.fromMap(Map<String, dynamic> map) {
    playlistId = map["playlistId"];
    title = map["title"];
    videos = map["videos"];
  }
}

class PlaylistProvider {
  late Database db;

  Future open(String path) async {
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
        CREATE TABLE Playlist (
          Id INTEGER NOT NULL, 
          Title TEXT NOT NULL,
          Thumbnail TEXT,
          Date CURRENT_TIMESTAMP,
        );
        CREATE TABLE Video (
          Id INTEGER NOT NULL, 
          Title TEXT NOT NULL,
          Description TEXT NOT NULL,
          Thumbnail TEXT NOT NULL,
          Author TEXT NOT NULL,
          Duration INTEGER NOT NULL,
          Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        );
        CREATE TABLE PlaylistVideoLink (
          PlaylistId INTEGER PRIMARY KEY AUTOINCREMENT, 
          VideoId TEXT NOT NULL,
          Position TEXT NOT NULL,
          PRIMARY KEY (PlaylistId, VideoId),
        );
        ''');
    });
  }

  Future<Playlist?> getPlaylists() async {
    List<Map<String, dynamic>> maps = await db.query(
      "Playlist",
      columns: ["playlistId", "title", ""],
    );
    if (maps.isNotEmpty) {
      return Playlist.fromMap(maps.first);
    }
    return null;
  }

  Future close() async => db.close();
}

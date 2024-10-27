import 'package:adless_youtube/Utils/globals.dart';
import 'package:adless_youtube/Utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class PlaylistListTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;

  const PlaylistListTile({
    super.key,
    required this.playlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    print("aaaaaa");
    return ListTile(
      leading: SizedBox(
        width: Globals.size(context).width / 3,
        child: Image.network(
          playlist.thumbnails.standardResUrl,
          width: 120,
          height: 70,
          fit: BoxFit.fill,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              "https://t3.ftcdn.net/jpg/02/68/55/60/360_F_268556012_c1WBaKFN5rjRxR2eyV33znK4qnYeKZjm.jpg",
              width: 120,
              height: 70,
              fit: BoxFit.fill,
            );
          },
        ),
      ),
      title: Text(
        playlist.title,
        style: TextStyle(color: YTTheme.white),
      ),
      subtitle: Text('${playlist.videoCount} videos'),
      onTap: onTap,
    );
  }
}
